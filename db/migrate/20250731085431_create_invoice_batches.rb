class CreateInvoiceBatches < ActiveRecord::Migration[7.1]
  def change
    create_table :invoice_batches do |t|
      t.integer :business_id, null: false, index: true

      t.string :batch_number, null: false, index: true
      t.text :notes
      t.date :start_date
      t.date :end_date
      t.jsonb :options
      t.string :status, null: false
      t.integer :author_id, null: false
      t.integer :invoices_count, null: false, default: 0
      t.integer :appointments_count, null: false, default: 0
      t.float :total_invoices_amount, null: false, default: 0.0

      t.timestamps
      t.datetime :deleted_at
    end

    create_table :invoice_batch_items do |t|
      t.integer :invoice_batch_id, null: false, index: true

      t.integer :invoice_id # Created invoice ID
      t.integer :appointment_id, null: false, index: true # Appointment ID
      t.string :status, null: false
      t.string :notes
    end
  end
end
