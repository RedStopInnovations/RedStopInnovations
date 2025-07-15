class AddContactIdToAvailabilities < ActiveRecord::Migration[5.0]
  def change
    add_column :availabilities, :contact_id, :integer
  end
end
