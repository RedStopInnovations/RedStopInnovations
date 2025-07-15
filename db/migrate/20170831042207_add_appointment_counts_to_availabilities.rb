class AddAppointmentCountsToAvailabilities < ActiveRecord::Migration[5.0]
  def change
    add_column :availabilities, :appointments_count, :integer, default: 0
    # TODO: this should be remove after deployed
    Availability.find_each do |avail|
      Availability.reset_counters(avail.id, :appointments)
    end
  end
end
