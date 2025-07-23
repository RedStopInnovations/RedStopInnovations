class AddMedicationsAllergiesIntolerancesToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :medications, :jsonb, default: [], array: true
    add_column :patients, :allergies, :jsonb, default: [], array: true
    add_column :patients, :intolerances, :jsonb, default: [], array: true
  end
end
