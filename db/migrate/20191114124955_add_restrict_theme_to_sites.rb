class AddRestrictThemeToSites < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :restrict_theme, :boolean, default: false
  end
end
