class AddAuthorIdToTreatmentNotes < ActiveRecord::Migration[5.0]
  def change
    add_column :treatments, :author_id, :integer
    add_index :treatments, :author_id
  end
end
