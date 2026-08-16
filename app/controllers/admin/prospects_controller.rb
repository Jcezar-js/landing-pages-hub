# --- início: lógica nossa (prospecção de clientes via Google Places API) ---
class Admin::ProspectsController < ApplicationController
  layout "admin"

  def index
    @used = PlaceSearch.used_this_month
    @remaining = PlaceSearch.remaining
    @query = params[:q].to_s.strip
    # `check_box` manda hidden "0" quando desmarcado: comparar com "1" em vez de
    # perguntar `present?`, senão o filtro nunca mais desliga.
    @sem_site = params[:sem_site] == "1"
    return if @query.blank? || @remaining.zero?

    @results = PlaceSearch.cached_search(@query)
    # Filtro de "sem site" acontece aqui, sobre o resultado que já veio: refazer
    # a busca no Google pra filtrar custaria outra requisição.
    @results = @results.reject { |result| result[:website].present? } if @sem_site
    @registered = Client.where(google_place_id: @results.map { |result| result[:place_id] })
                        .pluck(:google_place_id, :id).to_h
  rescue PlaceSearch::Error => e
    flash.now[:alert] = "Busca indisponível agora (#{e.message}). Tente de novo em instantes."
  end
end
# --- fim: lógica nossa ---
