class LandingPage < ApplicationRecord
  belongs_to :client
  has_many :sections, -> { order(:position) }, dependent: :destroy
  validates :slug, presence: true, uniqueness: true
  accepts_nested_attributes_for :sections, allow_destroy: true, reject_if: :all_blank
end
