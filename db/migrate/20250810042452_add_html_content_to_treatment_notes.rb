class AddHtmlContentToTreatmentNotes < ActiveRecord::Migration[7.1]
  def change
    add_column :treatments, :html_content, :text
  end
end
