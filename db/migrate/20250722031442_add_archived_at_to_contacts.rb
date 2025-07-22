class AddArchivedAtToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :archived_at, :datetime, null: true, default: nil
  end
end
