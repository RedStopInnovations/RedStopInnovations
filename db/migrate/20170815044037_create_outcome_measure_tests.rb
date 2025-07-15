class CreateOutcomeMeasureTests < ActiveRecord::Migration[5.0]
  def change
    create_table :outcome_measure_tests do |t|
      t.integer :outcome_measure_id, null: false
      t.date :date_performed, null: false
      t.float :result, null: false
      t.timestamps

      t.index :outcome_measure_id, name: :index_outcome_measure_id
    end
  end
end
