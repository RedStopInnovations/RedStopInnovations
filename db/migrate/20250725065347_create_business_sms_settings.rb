class CreateBusinessSmsSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :sms_settings do |t|
      t.references :business, null: false, index: { unique: true }
      t.boolean :enabled, default: false, null: false # Indicates if sending SMS is enabled for the business.
      t.boolean :enabled_two_way, default: false, null: false
      t.string :twilio_number # The Twilio number used for sending and receiving messages
      t.timestamps
    end
  end
end
