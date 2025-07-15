class AddMedicareAndDvaToPatients < ActiveRecord::Migration[5.0]
  def change
    add_column :patients, :medicare_details, :jsonb, default: {}
    add_column :patients, :dva_details, :jsonb, default: {}
  end
end
