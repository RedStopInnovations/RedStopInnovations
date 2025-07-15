class AddStatusToTreatments < ActiveRecord::Migration[5.0]
  def change
    add_column :treatments, :status, :string
  end
end
