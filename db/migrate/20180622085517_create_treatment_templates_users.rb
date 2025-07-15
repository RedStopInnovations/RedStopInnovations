class CreateTreatmentTemplatesUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :treatment_templates_users do |t|
      t.integer :treatment_template_id, null: false
      t.integer :user_id, null: false
    end
  end
end
