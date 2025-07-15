class MakeInvoiceIdNullalbeForPayments < ActiveRecord::Migration[5.0]
  def self.up
    change_table :payments do |t|
      t.change :invoice_id, :integer, null: true, index: true
    end
  end

  def self.down
  end
end
