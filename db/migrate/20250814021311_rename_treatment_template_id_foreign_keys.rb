class RenameTreatmentTemplateIdForeignKeys < ActiveRecord::Migration[7.1]
  def change
    rename_column :treatments, :treatment_template_id, :treatment_note_template_id
    rename_column :appointment_types, :default_treatment_template_id, :treatment_note_template_id
  end
end
