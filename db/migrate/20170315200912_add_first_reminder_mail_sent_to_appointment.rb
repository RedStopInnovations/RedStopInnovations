class AddFirstReminderMailSentToAppointment < ActiveRecord::Migration[5.0]
  def change
    add_column :appointments, :first_reminder_mail_sent, :boolean, default: false
  end
end
