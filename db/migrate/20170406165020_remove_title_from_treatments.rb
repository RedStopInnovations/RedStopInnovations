class RemoveTitleFromTreatments < ActiveRecord::Migration[5.0]
  def change
    remove_column :treatments, :title, :string
  end
end
