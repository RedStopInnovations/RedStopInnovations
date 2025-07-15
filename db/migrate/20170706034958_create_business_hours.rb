class CreateBusinessHours < ActiveRecord::Migration[5.0]
  def change
    create_table :business_hours do |t|
      t.integer :practitioner_id, null: false
      t.integer :day_of_week, null: false
      t.string :start_time, null: false
      t.string :end_time, null: false
      t.boolean :active, null: false, default: true

      t.index :practitioner_id
      t.index [:practitioner_id, :day_of_week], unique: true
    end
  end
end
