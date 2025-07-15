class CreateContactStatements < ActiveRecord::Migration[5.0]
  def change
    create_table :contact_statements do |t|
      t.integer :contact_id
      t.integer :patient_id
      t.date :start_date
      t.date :end_date
      t.string :number

      t.timestamps

      t.index :contact_id
      t.index :patient_id
    end
  end
end
