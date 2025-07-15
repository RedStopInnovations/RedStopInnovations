class RemoveDraftFromTreatments < ActiveRecord::Migration[5.0]
  def change
    remove_column :treatments, :draft, :boolean
  end
end
