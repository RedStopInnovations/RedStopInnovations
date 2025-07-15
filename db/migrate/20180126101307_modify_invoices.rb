class ModifyInvoices < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :service_ids, :integer, array: true, default: []
    add_column :invoices, :diagnose_ids, :integer, array: true, default: []
    add_column :invoice_settings, :enable_services, :boolean, default: false
    add_column :invoice_settings, :enable_diagnosis, :boolean, default: false
  end
end
