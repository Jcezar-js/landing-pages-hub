class AddPlacesFieldsToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :google_place_id, :string
    add_index :clients, :google_place_id, unique: true
    add_column :clients, :address, :string
    add_column :clients, :phone, :string
    add_column :clients, :website, :string
  end
end
