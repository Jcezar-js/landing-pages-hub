class Client < ApplicationRecord
  has_one :landing_page, dependent: :destroy
  validates :name, presence: true
end
