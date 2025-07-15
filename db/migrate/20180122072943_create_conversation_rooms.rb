class CreateConversationRooms < ActiveRecord::Migration[5.0]
  def change
    create_table :conversation_rooms do |t|
      t.integer :business_id
      t.string :url
      t.timestamps
    end
  end
end
