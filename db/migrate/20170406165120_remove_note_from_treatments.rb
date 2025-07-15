class RemoveNoteFromTreatments < ActiveRecord::Migration[5.0]
  def change
    remove_column :treatments, :note, :text
  end
end
