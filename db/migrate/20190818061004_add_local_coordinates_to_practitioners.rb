class AddLocalCoordinatesToPractitioners < ActiveRecord::Migration[5.0]
  def change
    add_column :practitioners, :local_latitude, :float
    add_column :practitioners, :local_longitude, :float
  end
end
