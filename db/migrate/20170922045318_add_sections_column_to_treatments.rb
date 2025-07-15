class AddSectionsColumnToTreatments < ActiveRecord::Migration[5.0]
  def change
    add_column :treatments, :sections, :text
  end
end
