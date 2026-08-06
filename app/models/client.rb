class Client < ApplicationRecord
  has_one :landing_page, dependent: :destroy
end
