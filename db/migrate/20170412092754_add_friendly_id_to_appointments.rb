class AddFriendlyIdToAppointments < ActiveRecord::Migration[5.0]
  def change
    add_column :appointments, :fid, :string, null: false, default: ''
    add_index :appointments, :fid
  end
end
