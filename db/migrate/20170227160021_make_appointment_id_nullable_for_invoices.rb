class MakeAppointmentIdNullableForInvoices < ActiveRecord::Migration[5.0]
  def change
    change_table :invoices do |t|
      t.change :appointment_id, :integer, null: true, index: true
    end
  end
end
