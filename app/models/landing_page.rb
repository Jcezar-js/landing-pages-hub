class LandingPage < ApplicationRecord
  belongs_to :client
  has_many :sections, -> { order(:position) }, dependent: :destroy
  validates :slug, presence: true, uniqueness: true
end
