class AddBusinessIdToPatients < ActiveRecord::Migration[5.0]
  def change
    add_column :patients, :business_id, :integer, null: false, default: 0
  end
end
