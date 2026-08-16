# --- início: lógica nossa (contador de chamadas pagas à Places API) ---
# Uma linha por chamada real à API — cache hit não registra nada. É tabela, e não
# contador em Rails.cache, porque é guarda de custo: cache pode ser esvaziado a
# qualquer momento e zeraria o freio em silêncio.
class PlaceSearchLog < ApplicationRecord
  scope :this_month, -> { where(created_at: Time.current.all_month) }
end
# --- fim: lógica nossa ---
