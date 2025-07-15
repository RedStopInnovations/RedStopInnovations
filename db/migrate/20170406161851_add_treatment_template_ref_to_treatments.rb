class AddTreatmentTemplateRefToTreatments < ActiveRecord::Migration[5.0]
  def change
    add_reference :treatments, :treatment_template, foreign_key: true
  end
end
