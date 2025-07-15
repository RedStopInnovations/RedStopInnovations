class AddAuthorNameToTreatments < ActiveRecord::Migration[7.0]
  def change
    add_column :treatments, :author_name, :string
  end
end
