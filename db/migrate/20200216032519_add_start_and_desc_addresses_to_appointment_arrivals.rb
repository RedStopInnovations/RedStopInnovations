class AddStartAndDescAddressesToAppointmentArrivals < ActiveRecord::Migration[5.2]
  def change
    add_column :appointment_arrivals, :travel_start_address, :string
    add_column :appointment_arrivals, :travel_dest_address, :string
  end
end
