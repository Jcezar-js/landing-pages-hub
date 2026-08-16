# --- início: lógica nossa (busca de negócios na Google Places API (New)) ---
# Não é ActiveRecord: é o objeto que fala com a API externa. Fica em app/models
# porque é objeto de domínio — o projeto usa MVC puro, sem camada de service.
require "net/http"

class PlaceSearch
  Error = Class.new(StandardError)

  ENDPOINT = URI("https://places.googleapis.com/v1/places:searchText")

  # Metade do teto gratuito do SKU Enterprise (1.000/mês), pra sobrar margem
  # antes de qualquer cobrança. Sobrescrevível por ENV se o uso crescer.
  MONTHLY_LIMIT = Integer(ENV.fetch("PLACES_MONTHLY_LIMIT", 500))

  # O field mask escolhe o SKU cobrado: websiteUri, nationalPhoneNumber, rating e
  # userRatingCount são Enterprise (1.000 requisições grátis/mês). Vale o custo —
  # é o websiteUri que identifica quem ainda não tem site. `places.photos` fica de
  # fora de propósito: cada foto exigiria uma segunda requisição paga em /media.
  FIELD_MASK = %w[
    places.id
    places.displayName
    places.formattedAddress
    places.nationalPhoneNumber
    places.websiteUri
    places.googleMapsUri
    places.rating
    places.userRatingCount
    places.businessStatus
  ].join(",").freeze

  # Cache aqui não é performance, é freio de custo: sem ele, F5 e botão voltar do
  # navegador viram requisição paga. 12h fica bem abaixo do teto de 30 dias que os
  # Termos do Google permitem para conteúdo de Places. Erro na chamada não grava
  # cache nem log — `fetch` não escreve quando o bloco levanta exceção.
  def self.cached_search(query)
    Rails.cache.fetch("place_search/#{query.downcase.strip}", expires_in: 12.hours) do
      search(query).tap { |results| PlaceSearchLog.create!(query: query, results_count: results.size) }
    end
  end

  def self.used_this_month
    PlaceSearchLog.this_month.count
  end

  def self.remaining
    [ MONTHLY_LIMIT - used_this_month, 0 ].max
  end

  def self.parse(payload)
    Array(payload["places"]).map do |place|
      {
        place_id: place["id"],
        name: place.dig("displayName", "text"),
        address: place["formattedAddress"],
        phone: place["nationalPhoneNumber"],
        website: place["websiteUri"],
        maps_url: place["googleMapsUri"],
        rating: place["rating"],
        rating_count: place["userRatingCount"],
        status: place["businessStatus"]
      }
    end
  end

  def self.search(query)
    key = ENV["GOOGLE_MAPS_API_KEY"].presence
    raise Error, "GOOGLE_MAPS_API_KEY não configurada" if key.nil?

    response = Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true, open_timeout: 3, read_timeout: 8) do |http|
      http.post(
        ENDPOINT.path,
        { textQuery: query, pageSize: 20, languageCode: "pt-BR", regionCode: "BR" }.to_json,
        "Content-Type" => "application/json",
        "X-Goog-Api-Key" => key,
        "X-Goog-FieldMask" => FIELD_MASK
      )
    end

    # Só o código HTTP na mensagem: o corpo de erro do Google pode ecoar a
    # requisição, e mensagem de erro costuma acabar em log.
    raise Error, "Google respondeu #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    parse(JSON.parse(response.body))
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, JSON::ParserError => e
    raise Error, e.class.name
  end
end
# --- fim: lógica nossa ---
