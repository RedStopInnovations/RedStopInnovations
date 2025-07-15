class CreateOutcomeMeasureTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :outcome_measure_types do |t|
      t.integer :business_id, null: false
      t.string :name, null: false
      t.text :description
      t.string :outcome_type, null: false
      t.string :unit

      t.timestamps
      t.index :business_id
    end
  end
end
