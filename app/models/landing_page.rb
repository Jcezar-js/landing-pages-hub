class LandingPage < ApplicationRecord
  belongs_to :client
  has_many :sections, -> { order(:position) }, dependent: :destroy
  validates :slug, presence: true, uniqueness: true
  validates :template, inclusion: { in: %w[loja pessoal] }
end
