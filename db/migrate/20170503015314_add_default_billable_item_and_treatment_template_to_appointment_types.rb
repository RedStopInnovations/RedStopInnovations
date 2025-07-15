class AddDefaultBillableItemAndTreatmentTemplateToAppointmentTypes < ActiveRecord::Migration[5.0]
  def change
    add_column :appointment_types, :default_billable_item_id, :integer
    add_column :appointment_types, :default_treatment_template_id, :integer
  end
end
