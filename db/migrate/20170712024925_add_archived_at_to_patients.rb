class AddArchivedAtToPatients < ActiveRecord::Migration[5.0]
  def change
    add_column :patients, :archived_at, :datetime
  end
end
