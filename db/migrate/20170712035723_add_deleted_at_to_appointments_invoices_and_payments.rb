class AddDeletedAtToAppointmentsInvoicesAndPayments < ActiveRecord::Migration[5.0]
  def change
    add_column :invoices, :deleted_at, :datetime
    add_index :invoices, :deleted_at
    remove_index :invoices, :business_id
    add_index :invoices, :business_id, where: "deleted_at IS NULL"

    add_column :appointments, :deleted_at, :datetime
    add_index :appointments, :deleted_at

    add_column :payments, :deleted_at, :datetime
    add_index :payments, :deleted_at
    add_index :payments, :business_id, where: "deleted_at IS NULL"
  end
end
