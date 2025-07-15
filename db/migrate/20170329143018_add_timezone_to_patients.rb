class AddTimezoneToPatients < ActiveRecord::Migration[5.0]
  def change
    add_column :patients, :timezone, :string, default: "Australia/Brisbane"
  end
end
