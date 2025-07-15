class CreateBusinessInvoices < ActiveRecord::Migration[5.0]
  def change
    create_table :business_invoices do |t|
      t.references :business
      t.datetime :issue_date
      t.decimal :subtotal, precision: 10, scale: 2, default: 0
      t.decimal :tax, precision: 10, scale: 2, default: 0
      t.decimal :discount, precision: 10, scale: 2, default: 0
      t.decimal :amount, precision: 10, scale: 2, default: 0
      t.string :payment_status
      t.datetime :date_closed
      t.string :invoice_number
      t.string :stripe_payment_id
      t.timestamps
    end
  end
end
