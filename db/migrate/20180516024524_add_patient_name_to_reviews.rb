class AddPatientNameToReviews < ActiveRecord::Migration[5.0]
  def change
    add_column :reviews, :patient_name, :string, null: false, default: ''
  end
end
