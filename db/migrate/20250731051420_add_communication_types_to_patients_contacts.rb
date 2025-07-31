class AddCommunicationTypesToPatientsContacts < ActiveRecord::Migration[7.1]
  def change
    change_table :patient_contacts do |t|
      t.boolean :for_appointments, default: false, null: false
      t.boolean :for_invoices, default: false, null: false
      t.boolean :for_treatment_notes, default: false, null: false
    end
  end
end
