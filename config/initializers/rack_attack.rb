# --- início: lógica nossa (rate limiting da autenticação do admin) ---
# Fora de test o store é o Rails.cache (solid_cache em produção), que é compartilhado
# entre os workers do Puma — um MemoryStore por processo multiplicaria o limite pelo
# WEB_CONCURRENCY e zeraria a contagem a cada deploy. Em test o Rails.cache é
# :null_store, onde nada é contado e o throttle nunca dispararia.
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new if Rails.env.test?

# Locais, não constantes: initializer roda no escopo do Object, então `LIMIT = 5` aqui
# viraria constante global da aplicação inteira. Os blocos abaixo capturam por closure.
limit = 5
period = 20.seconds

# Comparar `req.path` cru com a string exata deixa passar `/admins/sign_in.json`, que o
# Devise atende igual. E não dá pra recortar o sufixo com `\.\w+\z`: o segmento de
# formato do Rails é `[^/.?]+`, então `.js-on` (hífen não é `\w`) sobreviveria ao recorte
# e escaparia da contagem. Casar o path inteiro com o formato opcional fecha os dois.
auth_post = lambda do |req, path|
  req.post? && req.path.match?(/\A#{Regexp.escape(path)}(?:\.[^\/]*)?\z/)
end

login_post = ->(req) { auth_post.call(req, "/admins/sign_in") }
reset_post = ->(req) { auth_post.call(req, "/admins/password") }

# `req.ip` (Rack) confia no X-Forwarded-For, que o cliente manda — rotacionar o header
# zera a contagem por IP. `action_dispatch.remote_ip` vem do ActionDispatch::RemoteIp,
# que roda antes deste middleware no stack e respeita a lista de proxies confiáveis.
client_ip = ->(req) { req.env["action_dispatch.remote_ip"].to_s.presence || req.ip }

# Precisa ler o params do jeito que o Rails lê. `Rack::Request#params` é GET.merge(POST)
# (corpo ganha), o Rails é request_parameters.merge(query_parameters) (query ganha) — se
# usar o do Rack, dá pra atacar uma conta pela query e despistar a contagem com email de
# ruído no corpo. E `params["admin"]` nem sempre é Hash: `admin=boom` estouraria TypeError.
auth_email = lambda do |req|
  admin = ActionDispatch::Request.new(req.env).params["admin"]
  email = admin["email"] if admin.is_a?(Hash)
  email.downcase.strip if email.is_a?(String) && email.present?
rescue ActionDispatch::Http::Parameters::ParseError
  nil
end

# O painel é 100% HTML: login por JSON só existe como caminho pra fugir do throttle por
# email, já que `req.params` não lê corpo JSON e o discriminador viraria nil.
# `media_type` já vem sem os parâmetros do header e em minúsculas — comparar o
# Content-Type cru barraria um `Application/X-WWW-Form-Urlencoded` legítimo.
form_media_types = %w[application/x-www-form-urlencoded multipart/form-data].freeze

Rack::Attack.blocklist("admin auth: form posts only") do |req|
  (login_post.call(req) || reset_post.call(req)) &&
    !form_media_types.include?(req.media_type)
end

# Rajada de um mesmo IP: pega força bruta simples contra qualquer conta.
Rack::Attack.throttle("admin logins/ip", limit: limit, period: period) do |req|
  client_ip.call(req) if login_post.call(req)
end

# Mesmo email vindo de IPs diferentes: pega ataque distribuído contra uma conta
# específica, que o throttle por IP sozinho não vê.
#
# Trade-off aceito: como o rack-attack roda antes da aplicação, ele não sabe se o login
# deu certo — conta tentativa, não falha. Quem souber o email do admin consegue mantê-lo
# fora sustentando tráfego (o mesmo efeito do :lockable do Devise). A janela de 20s é o
# que mantém isso barato: o "castigo" nunca passa de 20s e some sozinho quando o ataque
# para. Contar só falha exigiria incrementar o contador de dentro do app (hook de falha
# do Warden) — dívida anotada, não vale a complexidade enquanto o painel tem 1 admin.
Rack::Attack.throttle("admin logins/email", limit: limit, period: period) do |req|
  auth_email.call(req) if login_post.call(req)
end

# Reset de senha é o mesmo alvo por outra porta: serve pra enumerar emails cadastrados
# e pra inundar a caixa de um admin de verdade.
Rack::Attack.throttle("admin password resets/ip", limit: limit, period: period) do |req|
  client_ip.call(req) if reset_post.call(req)
end

Rack::Attack.throttle("admin password resets/email", limit: limit, period: period) do |req|
  auth_email.call(req) if reset_post.call(req)
end

# Sem isso o rack-attack devolve um "Retry later" seco, sem dizer por quanto tempo —
# admin legítimo que cai no limite fica sem saber se espera 20s ou 20min.
Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env["rack.attack.match_data"] || {}
  matched_period = match_data[:period].to_i
  epoch_time = match_data[:epoch_time].to_i
  retry_after = matched_period.positive? ? matched_period - (epoch_time % matched_period) : 0

  [
    429,
    { "content-type" => "text/plain; charset=utf-8", "retry-after" => retry_after.to_s },
    [ "Muitas tentativas de login. Tente novamente em #{retry_after} segundos.\n" ]
  ]
end
# --- fim: lógica nossa ---
