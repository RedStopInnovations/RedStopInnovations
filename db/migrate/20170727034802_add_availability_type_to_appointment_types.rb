class AddAvailabilityTypeToAppointmentTypes < ActiveRecord::Migration[5.0]
  def change
    change_table :appointment_types do |t|
      t.integer :availability_type_id
      t.index [:business_id, :availability_type_id], name: 'business_id_availability_type_id'
    end
  end
end
