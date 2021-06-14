class AddGroupToSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :settings, :group, :string
  end
end
