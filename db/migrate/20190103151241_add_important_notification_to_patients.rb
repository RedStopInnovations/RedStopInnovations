class AddImportantNotificationToPatients < ActiveRecord::Migration[5.0]
  def change
    add_column :patients, :important_notification, :text
  end
end
