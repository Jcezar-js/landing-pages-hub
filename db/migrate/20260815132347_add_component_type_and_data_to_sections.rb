class AddComponentTypeAndDataToSections < ActiveRecord::Migration[8.1]
  def change
    add_column :sections, :component_type, :string
    add_column :sections, :data, :jsonb, default: {}, null: false
    remove_column :sections, :content, :text
  end
end
