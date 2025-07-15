class AddFullNameToContacts < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :full_name, :string
  end
end
