class AddFullNameToPatients < ActiveRecord::Migration[5.0]
  def change
    add_column :patients, :full_name, :string
  end
end
