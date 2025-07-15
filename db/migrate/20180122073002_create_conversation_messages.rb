class CreateConversationMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :conversation_messages do |t|
      t.integer :conversation_room_id, index: true
      t.text :content
      t.integer :conversation_message_id, index: true
      t.integer :user_id, index: true

      t.timestamps
    end
  end
end
