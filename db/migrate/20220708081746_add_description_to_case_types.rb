class AddDescriptionToCaseTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :case_types, :description, :text
  end
end
