class AddDescriptionToAvailability < ActiveRecord::Migration[5.0]
  def change
    add_column :availabilities, :description, :text
  end
end
