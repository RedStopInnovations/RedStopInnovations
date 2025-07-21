class AddAddress3ToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :address3, :string, null: true, default: nil
  end
end
