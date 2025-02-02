# This migration comes from journal (originally 20141104130348)
class RenamePages < ActiveRecord::Migration[5.2]
  class Page < ApplicationRecord
    self.inheritance_column = nil
  end

  def up
    Page.where(publish: true).update_all(status: 'published')
    Page.where(publish: false).update_all(status: 'draft')

    rename_column :pages, :author_id, :user_id
    remove_column :pages, :kind, :string
    remove_column :pages, :event_begin, :datetime
    remove_column :pages, :event_end, :datetime
    remove_column :pages, :event_email, :string
    remove_column :pages, :subject, :string
    remove_column :pages, :align, :string
    remove_column :pages, :type, :string
    remove_column :pages, :size, :string
    remove_column :pages, :publish, :boolean
    
    rename_table :pages, :journal_news

    rename_column :page_i18ns, :page_id, :journal_news_id

    rename_table :page_i18ns, :journal_news_i18ns

    #
    View.where(viewable_type: 'Page').update_all(viewable_type: 'Journal::News')
    MenuItem.where(target_type: 'Page').update_all(target_type: 'Journal::News')
    PostsRepository.where(post_type: 'Page').update_all(post_type: 'Journal::News')
    Sticker::Banner.where(target_type: 'Page').update_all(target_type: 'Journal::News')
  end

  def down
    rename_table :journal_news, :pages

    rename_column :pages, :user_id, :author_id
    add_column :pages, :kind, :string
    add_column :pages, :event_begin, :datetime
    add_column :pages, :event_end, :datetime
    add_column :pages, :event_email, :string
    add_column :pages, :subject, :string
    add_column :pages, :align, :string
    add_column :pages, :type, :string
    add_column :pages, :size, :string
    add_column :pages, :publish, :boolean, default: false

    Page.reset_column_information
    Page.where(status: 'published').update_all(publish: true)
    Page.where(status: ['draft', 'review']).update_all(publish: false)

    rename_table :journal_news_i18ns, :page_i18ns

    rename_column :page_i18ns, :journal_news_id, :page_id

    #
    View.where(viewable_type: 'Journal::News').update_all(viewable_type: 'Page')
    MenuItem.where(target_type: 'Journal::News').update_all(target_type: 'Page')
    PostsRepository.where(post_type: 'Journal::News').update_all(post_type: 'Page')
    Sticker::Banner.where(target_type: 'Journal::News').update_all(target_type: 'Page')
  end
end
