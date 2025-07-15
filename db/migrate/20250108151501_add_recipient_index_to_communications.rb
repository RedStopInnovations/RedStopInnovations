class AddRecipientIndexToCommunications < ActiveRecord::Migration[7.1]
  def change
    add_index :communications, [:recipient_id, :recipient_type]
    add_index :communications, [:source_type, :source_id]
  end
end
