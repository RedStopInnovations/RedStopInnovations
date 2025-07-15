class AddStatusAndMetaToCommunications < ActiveRecord::Migration[6.1]
  def change
    create_table :communication_delivery do |t|
      t.integer :communication_id, null: false, index: true

      t.string :recipient # The actual email address or mobile number(international formatted)

      t.string :status
      t.string :error_type
      t.string :error_message
      t.string :tracking_id, null: false, unique: true

      t.datetime :last_tried_at

      t.string :provider_id, null: false # sendgrid, twilio
      t.string :provider_resource_id # The unique identifier of the message provided by email/SMS service provider
      t.string :provider_delivery_status # The delivery status of message provided by email/SMS service provider

      t.json :provider_metadata # metadata of the Email/SMS service provider

      t.timestamps
    end
  end
end
