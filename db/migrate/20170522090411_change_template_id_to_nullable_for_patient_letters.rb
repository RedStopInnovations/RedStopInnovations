class ChangeTemplateIdToNullableForPatientLetters < ActiveRecord::Migration[5.0]
  def change
    change_column :patient_letters, :letter_template_id, :integer, null: true
  end
end
