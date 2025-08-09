class AddNewContentToTreatmentTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :treatment_templates, :content, :text
  end
end
