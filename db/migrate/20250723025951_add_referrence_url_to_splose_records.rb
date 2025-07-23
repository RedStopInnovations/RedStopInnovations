class AddReferrenceUrlToSploseRecords < ActiveRecord::Migration[7.1]
  def change
    add_column :splose_records, :reference_url, :string, null: true
  end
end
