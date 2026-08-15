class Section < ApplicationRecord
  COMPONENT_TYPES = %w[hero servicos depoimentos contato_whatsapp mapa sobre_mim experiencia].freeze

  belongs_to :landing_page
  has_many :photos, -> { order(:position) }, dependent: :destroy

  validates :component_type, inclusion: { in: COMPONENT_TYPES }
end
