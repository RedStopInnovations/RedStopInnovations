class AddSentAtToAppointmentArrivalTimes < ActiveRecord::Migration[5.0]
  def change
    add_column :appointment_arrival_times, :sent_at, :datetime
  end
end
