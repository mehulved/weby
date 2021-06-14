class ChangeColumnOnSettings < ActiveRecord::Migration[5.2]
  def change
    change_column :settings, :value, :text
  end
end
