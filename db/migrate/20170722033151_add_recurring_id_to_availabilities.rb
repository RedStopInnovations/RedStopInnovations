class AddRecurringIdToAvailabilities < ActiveRecord::Migration[5.0]
  def change
    add_column :availabilities, :recurring_id, :integer
    add_index :availabilities, :recurring_id
  end
end
