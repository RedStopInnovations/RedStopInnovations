class AddMedipassInfoToPatients < ActiveRecord::Migration[5.0]
  def change
    add_column :patients, :medipass_member_id, :string
  end
end
