class AddColumnsToPatients < ActiveRecord::Migration[5.0]
  def change
    add_column :patients, :phone_formated, :string
    add_column :patients, :mobile_formated, :string
  end
end
