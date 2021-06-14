class CreateSkins < ActiveRecord::Migration[5.2]
  def change
    create_table :skins do |t|
      t.references :site, index: true
      t.string :theme
      t.string :name
      t.text :variables
      t.boolean :active, default: false

      t.timestamps
    end
  end
end
