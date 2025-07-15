class CreateNotificationTypeSettings < ActiveRecord::Migration[6.1]
  def change
    create_table :notification_type_settings do |t|
      t.integer :business_id, index: true, null: false  # reference to "businesses.id"
      t.string :notification_type_id, null: false, index: true # reference to "notification_types.id"
      t.jsonb :enabled_delivery_methods, default: []

      t.jsonb :template, default: {}

      # "template" value format:
      #  {
      #    email_subject: '',
      #    email_body: '',
      #    sms_content: '',
      #  }

      t.boolean :enabled, default: true

      t.jsonb :config, default: {} # maybe add the "cc", "bcc". Or some appoitment constraints

      t.timestamps
    end
  end
end