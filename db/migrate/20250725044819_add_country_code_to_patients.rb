class AddCountryCodeToPatients < ActiveRecord::Migration[7.1]
  def change
    add_column :patients, :country_code, :string
  end
end
