class AddSectionsColumnToTreatmentTemplates < ActiveRecord::Migration[5.0]
  def change
    add_column :treatment_templates, :template_sections, :text
  end
end
