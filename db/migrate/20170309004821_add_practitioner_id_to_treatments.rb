class AddPractitionerIdToTreatments < ActiveRecord::Migration[5.0]
  def change
    add_column :treatments, :practitioner_id, :integer
  end
end
