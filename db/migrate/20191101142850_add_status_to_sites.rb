class AddStatusToSites < ActiveRecord::Migration[5.2]
  def change
    add_column :sites, :status, :string, default: 'active'
    add_index :sites, :status
  end
end
