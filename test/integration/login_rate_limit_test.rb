require "test_helper"

class LoginRateLimitTest < ActionDispatch::IntegrationTest
  # O rack-attack conta em janelas fixas (`Time.now.to_i / period`). Sem congelar o
  # relógio, uma rajada que cai em cima da virada da janela se divide em duas contagens
  # e nenhuma chega no limite — o teste passa quase sempre e falha sozinho de vez em
  # quando. O horário escolhido é múltiplo exato de 20s, ou seja, início de janela.
  setup do
    travel_to Time.zone.at(1_800_000_000)
    Rack::Attack.cache.store.clear
  end

  teardown do
    Rack::Attack.cache.store.clear
    travel_back
  end

  test "blocks sign in attempts after too many failures from the same ip" do
    6.times do
      post admin_session_path, params: { admin: { email: "admin1@example.com", password: "wrong" } }
    end

    assert_response :too_many_requests
  end

  test "does not block a normal amount of sign in attempts" do
    3.times do
      post admin_session_path, params: { admin: { email: "admin1@example.com", password: "wrong" } }
    end

    assert_response :unprocessable_entity
  end

  test "blocks attempts against the same email even when the ip changes" do
    6.times do |i|
      post admin_session_path,
        params: { admin: { email: "admin1@example.com", password: "wrong" } },
        headers: { "REMOTE_ADDR" => "203.0.113.#{i + 1}" }
    end

    assert_response :too_many_requests
  end

  test "does not block different emails coming from different ips" do
    6.times do |i|
      post admin_session_path,
        params: { admin: { email: "admin#{i}@example.com", password: "wrong" } },
        headers: { "REMOTE_ADDR" => "198.51.100.#{i + 1}" }
    end

    assert_response :unprocessable_entity
  end

  test "throttled response tells the admin how long to wait" do
    6.times do
      post admin_session_path, params: { admin: { email: "admin1@example.com", password: "wrong" } }
    end

    assert_response :too_many_requests
    # Retry-After é o que falta da janela, não a janela inteira — só o intervalo é estável.
    assert_includes 1..20, response.headers["Retry-After"].to_i
    assert_match(/muitas tentativas/i, response.body)
  end

  test "throttles the login path even with a format suffix" do
    6.times do
      post "/admins/sign_in.json", params: { admin: { email: "admin1@example.com", password: "wrong" } }
    end

    assert_response :too_many_requests
  end

  # O segmento de formato do Rails é `[^/.?]+`, não só `\w+` — um sufixo com hífen
  # chega no Devise igual e não pode escapar da contagem.
  test "throttles the login path with a format suffix that is not a plain word" do
    6.times do
      post "/admins/sign_in.js-on", params: { admin: { email: "admin1@example.com", password: "wrong" } }
    end

    assert_response :too_many_requests
  end

  test "throttles password resets with a format suffix that is not a plain word" do
    6.times do
      post "/admins/password.js-on", params: { admin: { email: "admin1@example.com" } }
    end

    assert_response :too_many_requests
  end

  test "rejects login attempts that are not html form posts" do
    post admin_session_path,
      params: { admin: { email: "admin1@example.com", password: "wrong" } }.to_json,
      headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :forbidden
  end

  # Atrás de proxy, o IP real é o último da cadeia do X-Forwarded-For (o proxy anexa).
  # Prefixo forjado pelo cliente não pode trocar o bucket do throttle.
  test "counts per real client ip even when x-forwarded-for is prefixed by the client" do
    6.times do |i|
      post admin_session_path,
        params: { admin: { email: "admin#{i}@example.com", password: "wrong" } },
        headers: { "HTTP_X_FORWARDED_FOR" => "9.9.9.#{i + 1}, 203.0.113.7" }
    end

    assert_response :too_many_requests
  end

  # O Devise lê o email pelo params do Rails (query ganha do corpo); se o throttle ler
  # pelo Rack (corpo ganha da query), dá pra atacar uma conta na query e despistar a
  # contagem com email de ruído no corpo.
  test "counts the email the app will actually authenticate, not the request body" do
    6.times do |i|
      post "#{admin_session_path}?admin[email]=admin1@example.com",
        params: { admin: { email: "noise#{i}@example.com", password: "wrong" } },
        headers: { "REMOTE_ADDR" => "203.0.113.#{100 + i}" }
    end

    assert_response :too_many_requests
  end

  test "accepts a form post whose content type differs only in case" do
    post admin_session_path,
      params: { admin: { email: "admin1@example.com", password: "wrong" } },
      headers: { "CONTENT_TYPE" => "Application/X-WWW-Form-Urlencoded" }

    assert_response :unprocessable_entity
  end

  test "does not blow up when the admin param is not a hash" do
    post admin_session_path, params: { admin: "boom" }

    assert_response :unprocessable_entity
  end

  test "blocks password reset flooding against the same email" do
    6.times do |i|
      post admin_password_path,
        params: { admin: { email: "admin1@example.com" } },
        headers: { "REMOTE_ADDR" => "192.0.2.#{i + 1}" }
    end

    assert_response :too_many_requests
  end
end
