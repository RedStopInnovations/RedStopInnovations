class AddXeroAccountCodeToBillableItems < ActiveRecord::Migration[5.0]
  def change
    add_column :billable_items, :xero_account_code, :string
  end
end
