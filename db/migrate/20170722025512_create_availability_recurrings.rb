class CreateAvailabilityRecurrings < ActiveRecord::Migration[5.0]
  def change
    create_table :availability_recurrings do |t|
      t.integer :practitioner_id, null: false
      t.datetime :last_repeat_at, null: false
      t.integer :repeats_count, null: false
      t.boolean :active, default: true

      t.index :practitioner_id
      t.index :active
      t.timestamps
    end
  end
end
