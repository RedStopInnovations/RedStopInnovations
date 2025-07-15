class CreateTreatmentTemplates < ActiveRecord::Migration[5.0]
  def change
    create_table :treatment_templates do |t|
	  t.references :business, null: false

      t.string :name
      t.string :print_name
      t.boolean :print_address
      t.boolean :print_birth
      t.boolean :print_ref_num
      t.boolean :print_doctor
      t.timestamps
    end

  end
end
