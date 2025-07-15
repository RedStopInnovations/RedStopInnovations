class ChangeImportFieldsInPatients < ActiveRecord::Migration[5.0]
  def change
    add_column :patients, :import_id, :integer
    remove_column :patients, :is_imported, :boolean
  end
end
