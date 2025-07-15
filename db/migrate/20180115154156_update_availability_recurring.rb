class UpdateAvailabilityRecurring < ActiveRecord::Migration[5.0]
  def change
    remove_column :availability_recurrings, :repeats_count, :integer
    remove_column :availability_recurrings, :active, :boolean, default: true
    remove_column :availability_recurrings, :last_repeat_at, :datetime

    change_table :availability_recurrings do |t|
      t.string :repeat_type, null: false, default: ''
      t.integer :repeat_total, null: false, default: 1
      t.integer :repeat_interval, null: false, default: 1
    end
  end
end
