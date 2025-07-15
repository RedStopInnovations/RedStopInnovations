class AddMoreDatesToReferrals < ActiveRecord::Migration[5.0]
  def change
    add_column :referrals, :contact_referrer_date, :date
    add_column :referrals, :contact_patient_date, :date
    add_column :referrals, :first_appoinment_date, :date
    add_column :referrals, :send_treatment_plan_date, :date
  end
end
