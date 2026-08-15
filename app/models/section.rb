class Section < ApplicationRecord
  COMPONENT_TYPES = %w[hero servicos depoimentos contato_whatsapp mapa sobre_mim experiencia].freeze

  belongs_to :landing_page
  has_many :photos, -> { order(:position) }, dependent: :destroy

  validates :component_type, inclusion: { in: COMPONENT_TYPES }
  validate :data_must_be_valid_json

  # --- início: lógica nossa (data:jsonb editado como texto no form admin) ---
  def data=(value)
    if value.is_a?(String)
      @data_json_invalid = false
      begin
        value = value.strip.presence ? JSON.parse(value) : {}
      rescue JSON::ParserError
        @data_json_invalid = true
        value = {}
      end
    end
    super(value)
  end

  private

  def data_must_be_valid_json
    errors.add(:data, "precisa ser um JSON válido (ex.: {\"titulo\": \"texto\"})") if @data_json_invalid
  end
  # --- fim: lógica nossa ---
end
