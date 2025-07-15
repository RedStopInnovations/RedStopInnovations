class AddEndDateToPatientCases < ActiveRecord::Migration[7.1]
  def change
    add_column :patient_cases, :end_date, :date
  end
end
