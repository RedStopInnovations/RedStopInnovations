class AddPolicyUrlToBusinessProfile < ActiveRecord::Migration[5.0]
  def change
    add_column :businesses, :policy_url, :string
  end
end
