class CreateTreatmentContents < ActiveRecord::Migration[5.0]
  def change
    create_table :treatment_contents do |t|

	    t.references :treatment, foreign_key: { to_table: :treatments }, index: true, null: false
	    t.references :section,   foreign_key: { to_table: :treatment_template_sections }, index: true, null: false
	    t.references :question,  foreign_key: { to_table: :treatment_template_questions }, index: true, null: false

      t.text   :content
      t.timestamps
    end
  end
end
