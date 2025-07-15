class AddFriendlyIdToAvailability < ActiveRecord::Migration[5.0]
  def change
    add_column :availabilities, :fid, :string, null: false, default: ''
    add_index :availabilities, :fid
  end
end
