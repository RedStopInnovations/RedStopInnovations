class CreateNotificationTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :notification_types, id: :string do |t|
      # t.string :id, # appointment.created, appointment.cancelled, referral.created, appointment.booked_online
      t.string :name, null: false
      t.text :description

      t.jsonb :available_delivery_methods, default: []

      t.jsonb :default_template, default: {}
        # "template" value format:
        #  {
        #    email_subject: '',
        #    email_body: '',
        #    sms_content: '',
        #  }
      t.jsonb :default_config, default: {}
    end
  end
end
