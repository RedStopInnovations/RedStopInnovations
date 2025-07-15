class CreateTreatmentTemplateSections < ActiveRecord::Migration[5.0]
  def change
    create_table :treatment_template_sections do |t|
	  t.references :template, foreign_key: { to_table: :treatment_templates }, index: true, null: false

      t.string :name
      t.integer :stype  
      t.integer :sorder
      t.timestamps
    end
  end
end
