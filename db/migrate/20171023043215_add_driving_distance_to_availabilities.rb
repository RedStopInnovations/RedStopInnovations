class AddDrivingDistanceToAvailabilities < ActiveRecord::Migration[5.0]
  def change
    add_column :availabilities, :driving_distance, :decimal, precision: 10, scale: 2
  end
end
