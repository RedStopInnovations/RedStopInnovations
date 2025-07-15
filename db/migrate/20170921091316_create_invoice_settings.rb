class CreateInvoiceSettings < ActiveRecord::Migration[5.0]
  def self.up
    create_table :invoice_settings do |t|
      t.integer :business_id, null: false
      t.integer :starting_invoice_number, null: false, default: 1

      t.datetime :updated_at
      t.index :business_id
    end

    Business.pluck(:id).each do |business_id|
      InvoiceSetting.create!(
        business_id: business_id
      )
    end
  end

  def self.down
    drop_table :invoice_settings
  end
end
