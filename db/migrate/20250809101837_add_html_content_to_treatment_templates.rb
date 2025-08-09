class AddHtmlContentToTreatmentTemplates < ActiveRecord::Migration[7.1]
  def change
    add_column :treatment_templates, :html_content, :text
  end
end
