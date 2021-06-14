class AddNewsIndexesToJournalNews < ActiveRecord::Migration[5.2]
  def up
    Weby::generate_search_indexes
  end

  def down
    Weby::drop_search_indexes
  end
end
