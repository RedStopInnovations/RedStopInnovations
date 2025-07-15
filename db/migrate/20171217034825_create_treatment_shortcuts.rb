class CreateTreatmentShortcuts < ActiveRecord::Migration[5.0]
  def change
    create_table :treatment_shortcuts do |t|
      t.text :content, null: false
      
      t.integer :business_id

      t.index :business_id
    end
  end
end
