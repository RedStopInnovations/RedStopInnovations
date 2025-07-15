class DropEmergenciesTable < ActiveRecord::Migration[5.0]
  def change
    drop_table :emergencies
  end
end
