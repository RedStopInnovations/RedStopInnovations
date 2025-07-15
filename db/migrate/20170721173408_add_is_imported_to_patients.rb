class AddIsImportedToPatients < ActiveRecord::Migration[5.0]
  def change
    add_column :patients, :is_imported, :boolean, default: false
  end
end
