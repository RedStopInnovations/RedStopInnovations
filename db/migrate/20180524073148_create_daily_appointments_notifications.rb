class CreateDailyAppointmentsNotifications < ActiveRecord::Migration[5.0]
  def change
    create_table :daily_appointments_notifications do |t|
      t.integer :practitioner_id, null: false, index: true
      t.date :date
      t.datetime :sent_at
    end
  end
end
