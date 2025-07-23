class AddCaseNumberToPatientCases < ActiveRecord::Migration[7.1]
  def change
    change_table :patient_cases do |t|
      t.string :case_number, null: true, default: nil
      t.datetime :issue_date, null: true
    end
  end
end
