class AddSoftDeleteToTreatmentTemplates < ActiveRecord::Migration[5.0]
  def change
    add_column :treatment_templates, :deleted_at, :datetime
    remove_index :treatment_templates, :business_id
    add_index :treatment_templates, :business_id, where: "deleted_at IS NULL"
  end
end
