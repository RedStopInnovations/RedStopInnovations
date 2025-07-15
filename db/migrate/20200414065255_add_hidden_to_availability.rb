class AddHiddenToAvailability < ActiveRecord::Migration[5.2]
  def change
    add_column :availabilities, :hide, :boolean, default: false, index: true
  end
end
