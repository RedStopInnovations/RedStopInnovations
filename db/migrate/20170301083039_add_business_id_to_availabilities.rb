class AddBusinessIdToAvailabilities < ActiveRecord::Migration[5.0]
  def change
    add_column :availabilities, :business_id, :integer
  end
end
