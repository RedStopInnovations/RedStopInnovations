class AddDistanceToAppointmentArrivals < ActiveRecord::Migration[5.0]
  def change
    add_column :appointment_arrival_times, :travel_distance, :decimal, precision: 10, scale: 2
  end
end
