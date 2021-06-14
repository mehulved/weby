class CreateAuthSources < ActiveRecord::Migration[5.2]
  def change
    create_table :auth_sources do |t|
      t.integer :user_id
      t.string :source_type
      t.string :source_login

      t.timestamps
    end
  end
end
