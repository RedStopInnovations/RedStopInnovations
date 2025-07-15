class AddNotesToContacts < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :notes, :text
  end
end
