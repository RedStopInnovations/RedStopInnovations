class AddDeletedAtToAvailability < ActiveRecord::Migration[7.1]
  def change
    add_column :availabilities, :deleted_at, :datetime, null: true
  end
end
