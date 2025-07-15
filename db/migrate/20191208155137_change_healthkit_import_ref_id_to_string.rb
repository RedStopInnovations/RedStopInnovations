class ChangeHealthkitImportRefIdToString < ActiveRecord::Migration[5.0]
  def change
    change_column :healthkit_records, :reference_id, :string
  end
end
