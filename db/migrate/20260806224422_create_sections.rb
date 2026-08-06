class CreateSections < ActiveRecord::Migration[8.1]
  def change
    create_table :sections do |t|
      t.references :landing_page, null: false, foreign_key: true
      t.string :title
      t.text :content
      t.integer :position

      t.timestamps
    end
  end
end
