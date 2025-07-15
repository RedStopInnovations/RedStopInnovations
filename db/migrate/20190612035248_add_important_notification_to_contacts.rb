class AddImportantNotificationToContacts < ActiveRecord::Migration[5.0]
  def change
    add_column :contacts, :important_notification, :text
  end
end
