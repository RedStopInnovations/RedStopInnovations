class RemoveOldTablesRelatedToTreatmentAndTemplates < ActiveRecord::Migration[7.1]
  def change
    drop_table :treatment_templates_users if table_exists?(:treatment_templates_users)
    drop_table :treatment_contents if table_exists?(:treatment_contents)
    drop_table :treatment_template_questions if table_exists?(:treatment_template_questions)
    drop_table :treatment_template_sections if table_exists?(:treatment_template_sections)
  end
end
