class RemoveRecepionistsTable < ActiveRecord::Migration[5.0]
  def change
    drop_table :receptionists
  end
end
