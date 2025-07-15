class AddPatientIdToPayment < ActiveRecord::Migration[5.0]
  def change
    change_table :payments do |t|
      t.integer :patient_id
      t.index :patient_id
    end
  end
end
