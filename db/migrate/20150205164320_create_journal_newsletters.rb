class CreateJournalNewsletters < ActiveRecord::Migration[5.2]
  def change
    create_table :journal_newsletters do |t|
      t.integer :site_id
      t.string :group
      t.string :email
      t.string :token
      t.boolean :confirm

      t.timestamps
    end
  end
end
