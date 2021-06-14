# This migration comes from feedback (originally 20151127172431)
class AddReadStatusMsgToFeedbackMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :feedback_messages, :read_status, :boolean, :default => false
  end
end
