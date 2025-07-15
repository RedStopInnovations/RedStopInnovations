class CreateBusinessHourBreaks < ActiveRecord::Migration[5.0]
  def change
    create_table :business_hour_breaks do |t|
      t.integer :business_hour_id, null: false
      t.string :start_time, null: false
      t.string :end_time, null: false

      t.index :business_hour_id
    end
  end
end
