class AddTaxIdToBillableItems < ActiveRecord::Migration[5.0]
  def change
    add_column :billable_items, :tax_id, :integer
    add_index :billable_items, :tax_id
  end
end
