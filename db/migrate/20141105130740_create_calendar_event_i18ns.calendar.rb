# This migration comes from calendar (originally 20140801145828)
class CreateCalendarEventI18ns < ActiveRecord::Migration[5.2]
  def change
    create_table :calendar_event_i18ns do |t|
      t.integer  :calendar_event_id
      t.integer  :locale_id
      t.string   :name
      t.string   :place
      t.text     :information

      t.timestamps
    end

    add_index :calendar_event_i18ns, :calendar_event_id
    add_index :calendar_event_i18ns, :locale_id

    add_foreign_key :calendar_event_i18ns, :calendar_events
    add_foreign_key :calendar_event_i18ns, :locales
  end
end
