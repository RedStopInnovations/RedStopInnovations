class AddIsInvoiceRequiredToAppointments < ActiveRecord::Migration[6.1]
  def change
    add_column :appointments, :is_invoice_required, :boolean, default: true
  end
end
