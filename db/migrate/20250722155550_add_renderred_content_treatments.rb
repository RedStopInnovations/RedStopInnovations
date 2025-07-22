class AddRenderredContentTreatments < ActiveRecord::Migration[7.1]
  def change
    add_column :treatments, :content, :text, null: true
  end
end
