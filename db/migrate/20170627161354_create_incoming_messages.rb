class CreateIncomingMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :incoming_messages do |t|
      t.integer :patient_id
      t.text :message
      t.datetime :received_at
      t.string :sender
      t.string :receiver

      t.timestamps
    end
  end
end
