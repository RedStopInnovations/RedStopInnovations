class AddBusinessIdToBillableItem < ActiveRecord::Migration[5.0]
  def change
    add_column :billable_items, :business_id, :integer
  end
end
