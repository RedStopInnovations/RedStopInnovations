class CreateAppointmentTypesPractitionersTable < ActiveRecord::Migration[5.0]
  def change
    create_table :appointment_types_practitioners do |t|
      t.integer :appointment_type_id, null: false
      t.integer :practitioner_id, null: false

      t.index :practitioner_id
    end
  end
end
