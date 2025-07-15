class AddCountNumbersToTreatmentTemplates < ActiveRecord::Migration[5.0]
  def change
    add_column :treatment_templates, :sections_count, :integer, default: 0
    add_column :treatment_templates, :questions_count, :integer, default: 0
  end
end
