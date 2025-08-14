class RemoveUnusedColumnsFromTreatmentTemplates < ActiveRecord::Migration[7.1]
  def change
    remove_column :treatment_templates, :print_name
    remove_column :treatment_templates, :print_address
    remove_column :treatment_templates, :print_birth
    remove_column :treatment_templates, :print_ref_num
    remove_column :treatment_templates, :print_doctor
    remove_column :treatment_templates, :template_sections
    remove_column :treatment_templates, :sections_count
    remove_column :treatment_templates, :questions_count
  end
end
