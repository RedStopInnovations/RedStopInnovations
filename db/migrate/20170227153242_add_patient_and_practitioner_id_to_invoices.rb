class AddPatientAndPractitionerIdToInvoices < ActiveRecord::Migration[5.0]
  def change
    change_table :invoices do |t|
      t.references :patient
      t.references :practitioner
    end
  end
end
