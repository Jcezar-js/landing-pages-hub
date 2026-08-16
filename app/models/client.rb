class Client < ApplicationRecord
  has_one :landing_page, dependent: :destroy
  validates :name, presence: true
  # --- início: lógica nossa (identidade do negócio no Google, vinda da prospecção) ---
  # `allow_nil`: cliente cadastrado à mão não tem place_id, e vários NULL não
  # podem colidir entre si. O índice único no banco cobre a corrida entre dois
  # cadastros simultâneos do mesmo negócio.
  validates :google_place_id, uniqueness: true, allow_nil: true
  # --- fim: lógica nossa ---
end
