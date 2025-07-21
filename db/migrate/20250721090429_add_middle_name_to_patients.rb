class AddMiddleNameToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :middle_name, :string
  end
end
