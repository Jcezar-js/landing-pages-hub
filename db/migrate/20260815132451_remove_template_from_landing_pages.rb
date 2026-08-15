class RemoveTemplateFromLandingPages < ActiveRecord::Migration[8.1]
  def change
    remove_column :landing_pages, :template, :string
  end
end
