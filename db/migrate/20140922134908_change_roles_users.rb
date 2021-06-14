class ChangeRolesUsers < ActiveRecord::Migration[5.2]
  def change
    add_index(:roles_users, [:role_id, :user_id], unique: true)
  end
end
