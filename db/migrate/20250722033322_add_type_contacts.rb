class AddTypeContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :contact_type, :string, null: true
  end
end
