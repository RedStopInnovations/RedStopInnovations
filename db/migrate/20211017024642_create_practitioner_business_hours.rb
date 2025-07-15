class CreatePractitionerBusinessHours < ActiveRecord::Migration[5.2]
  def change
    create_table :practitioner_business_hours do |t|
      t.integer :practitioner_id, null: false, index: true
      t.integer :day_of_week, null: false
      t.boolean :active, default: true
      t.json :availability
    end
  end
end
