class AddOneWeekReminderSentToAppointments < ActiveRecord::Migration[5.2]
  def change
    add_column :appointments, :one_week_reminder_sent, :boolean, default: false
  end
end
