class AddAddress3ToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :address3, :string, null: true, default: nil
  end
end
