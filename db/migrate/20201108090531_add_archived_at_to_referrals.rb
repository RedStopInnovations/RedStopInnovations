class AddArchivedAtToReferrals < ActiveRecord::Migration[5.2]
  def change
    add_column :referrals, :archived_at, :datetime, index: true
  end
end
