require "test_helper"

class AdminProspectsTest < ActionDispatch::IntegrationTest
  RESULTS = [
    {
      place_id: "ChIJcomsite", name: "Barbearia Goldens", address: "R. Áurea, 326",
      phone: "(11) 5539-5678", website: "https://goldens.example.com",
      maps_url: "https://maps.google.com/?cid=1", rating: 5, rating_count: 541, status: "OPERATIONAL"
    },
    {
      place_id: "ChIJsemsite", name: "Barbearia Rio Grande", address: "R. Rio Grande, 138",
      phone: "(11) 94949-8118", website: nil,
      maps_url: "https://maps.google.com/?cid=2", rating: 4.7, rating_count: 201, status: "OPERATIONAL"
    }
  ].freeze

  setup do
    sign_in admins(:one)
  end

  # Abrir a tela não pode custar dinheiro: só o submit da busca chama a API.
  test "index sem busca não chama a API" do
    stubbing(PlaceSearch, :cached_search, ->(_query) { flunk "não deveria chamar a API sem busca" }) do
      get admin_prospects_path
    end

    assert_response :success
    assert_select "form input[name=q]"
  end

  test "index com busca lista os resultados com link do Google Maps" do
    search do
      get admin_prospects_path(q: "barbearia em Vila Mariana")
    end

    assert_response :success
    assert_select "td", text: /Barbearia Goldens/
    assert_select "td", text: /R. Áurea, 326/
    assert_select "a[href=?][target=_blank]", "https://maps.google.com/?cid=1"
  end

  test "resultado sem site é destacado e o filtro esconde quem tem site" do
    search do
      get admin_prospects_path(q: "barbearia em Vila Mariana")
    end
    assert_select "td", text: /sem site/

    search do
      get admin_prospects_path(q: "barbearia em Vila Mariana", sem_site: "1")
    end
    assert_select "body", text: /Barbearia Rio Grande/
    assert_select "body", { text: /Barbearia Goldens/, count: 0 }
  end

  # `check_box` do Rails manda um hidden "0" junto quando desmarcado — testar só
  # `present?` no param ligaria o filtro pra sempre depois do primeiro submit.
  test "checkbox desmarcado não filtra" do
    search do
      get admin_prospects_path(q: "barbearia em Vila Mariana", sem_site: "0")
    end

    assert_select "body", text: /Barbearia Goldens/
  end

  test "negócio já cadastrado aparece com link para o cliente" do
    client = Client.create!(name: "Barbearia Goldens", google_place_id: "ChIJcomsite")

    search do
      get admin_prospects_path(q: "barbearia em Vila Mariana")
    end

    assert_select "a[href=?]", edit_admin_client_path(client)
  end

  test "estourado o limite mensal, a busca não chega na API" do
    rows = Array.new(PlaceSearch::MONTHLY_LIMIT) do |i|
      { query: "busca #{i}", results_count: 0, created_at: Time.current, updated_at: Time.current }
    end
    PlaceSearchLog.insert_all(rows)

    stubbing(PlaceSearch, :cached_search, ->(_query) { flunk "limite atingido não pode chamar a API" }) do
      get admin_prospects_path(q: "barbearia em Vila Mariana")
    end

    assert_response :success
    assert_select "body", text: /limite/i
  end

  test "erro da API vira aviso na tela, não exceção" do
    stubbing(PlaceSearch, :cached_search, ->(_query) { raise PlaceSearch::Error, "Google respondeu 500" }) do
      get admin_prospects_path(q: "barbearia em Vila Mariana")
    end

    assert_response :success
    assert_select ".flash--alert", text: /indisponível/i
  end

  test "contador de buscas do mês aparece na tela" do
    PlaceSearchLog.create!(query: "padaria em Osasco", results_count: 3)

    get admin_prospects_path

    assert_select "body", text: /1 de #{PlaceSearch::MONTHLY_LIMIT}/
  end

  # O log da busca nasce dentro de `cached_search`. Ler o contador antes dessa
  # chamada mostra sempre um número atrasado em uma busca — o admin só descobria
  # o consumo real no próximo carregamento da página.
  test "contador já inclui a busca recém-feita" do
    logged_search do
      get admin_prospects_path(q: "barbearia em Vila Mariana")
    end

    assert_select "body", text: /1 de #{PlaceSearch::MONTHLY_LIMIT}/
  end

  test "cache hit não mexe no contador" do
    PlaceSearchLog.create!(query: "padaria em Osasco", results_count: 3)

    search do
      get admin_prospects_path(q: "padaria em Osasco")
    end

    assert_select "body", text: /1 de #{PlaceSearch::MONTHLY_LIMIT}/
  end

  # Trocar de aba e voltar não pode zerar a busca: o link da sidebar carrega de
  # volta o último filtro usado.
  test "aba de prospecção lembra da última busca" do
    search do
      get admin_prospects_path(q: "barbearia em Vila Mariana", sem_site: "1")
    end

    get admin_root_path

    assert_select "a[href=?]", admin_prospects_path(q: "barbearia em Vila Mariana", sem_site: "1")
  end

  private

  def search(&block)
    stubbing(PlaceSearch, :cached_search, ->(_query) { RESULTS }, &block)
  end

  # Igual ao `search`, mas grava o log como a chamada real grava — é o que
  # diferencia busca nova (cobrada, conta) de cache hit (de graça, não conta).
  def logged_search(&block)
    stubbing(PlaceSearch, :cached_search, lambda { |query|
      PlaceSearchLog.create!(query: query, results_count: RESULTS.size)
      RESULTS
    }, &block)
  end
end
