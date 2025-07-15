class FixAvailabilityAndRecurringsTable < ActiveRecord::Migration[5.0]
  def change
    change_table :availabilities do |t|
      t.remove :repeat_frequency
      t.remove :repeat_total
      t.string :group_id, index: true # Unique ID for grouping repeats
    end

    drop_table :recurrings
  end
end
