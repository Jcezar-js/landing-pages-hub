class Section < ApplicationRecord
  belongs_to :landing_page
  has_many :photos, -> { order(:position) }, dependent: :destroy
end
