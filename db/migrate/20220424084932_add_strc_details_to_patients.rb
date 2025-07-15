class AddStrcDetailsToPatients < ActiveRecord::Migration[6.1]
  def change
    add_column :patients, :strc_details, :jsonb, default: {}
  end
end
