class CreateInvoices < ActiveRecord::Migration[5.0]
  def change
    create_table :invoices do |t|
      t.date :issue_date
      t.integer :subtotal
      t.integer :tax
      t.integer :discount
      t.integer :amount
      t.text :notes
      t.boolean :status
      t.date :date_closed
      t.integer :outstanding

      t.references :appointment, null: false

      t.timestamps
    end
  end
end
