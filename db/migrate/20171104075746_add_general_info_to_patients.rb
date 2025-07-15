class AddGeneralInfoToPatients < ActiveRecord::Migration[5.0]
  def change
    add_column :patients, :general_info, :text
  end
end
