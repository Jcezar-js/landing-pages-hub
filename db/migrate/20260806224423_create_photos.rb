class CreatePhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :photos do |t|
      t.references :section, null: false, foreign_key: true
      t.string :file_description
      t.integer :position

      t.timestamps
    end
  end
end
