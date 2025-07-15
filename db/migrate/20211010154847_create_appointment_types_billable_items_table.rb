class CreateAppointmentTypesBillableItemsTable < ActiveRecord::Migration[5.2]
  def change
    create_table :appointment_types_billable_items do |t|
      t.integer :appointment_type_id, null: false, index: true
      t.integer :billable_item_id, null: false, index: true
    end
  end
end
