class CreateLandingPages < ActiveRecord::Migration[8.1]
  def change
    create_table :landing_pages do |t|
      t.references :client, null: false, foreign_key: true
      t.string :slug
      t.string :template

      t.timestamps
    end
    add_index :landing_pages, :slug, unique: true
  end
end
