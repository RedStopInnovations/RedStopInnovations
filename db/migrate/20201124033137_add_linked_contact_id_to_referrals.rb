class AddLinkedContactIdToReferrals < ActiveRecord::Migration[5.2]
  def change
    add_column :referrals, :linked_contact_id, :integer
  end
end
