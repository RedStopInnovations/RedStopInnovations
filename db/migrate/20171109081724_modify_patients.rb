class ModifyPatients < ActiveRecord::Migration[5.0]
  def change
    add_column :patients, :next_of_kin, :text
  end
end
