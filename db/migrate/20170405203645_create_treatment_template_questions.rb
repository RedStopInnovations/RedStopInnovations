class CreateTreatmentTemplateQuestions < ActiveRecord::Migration[5.0]
  def change
    create_table :treatment_template_questions do |t|
	    t.references :section, foreign_key: { to_table: :treatment_template_sections }, index: true, null: false

      t.string :name
      t.integer :qtype  
      t.integer :qorder
      t.text   :content
      t.timestamps
    end
  end
end
