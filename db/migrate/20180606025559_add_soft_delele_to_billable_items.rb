class AddSoftDeleleToBillableItems < ActiveRecord::Migration[5.0]
  def change
    add_column :billable_items, :deleted_at, :datetime
  end
end
