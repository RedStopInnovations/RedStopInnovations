class AddClaimIdsToInvoiceClaimns < ActiveRecord::Migration[5.0]
  def change
    add_column :invoice_claims, :claim_id, :string
    add_column :invoice_claims, :medicare_claim_id, :string
    rename_column :invoice_claims, :claiming_transaction_id, :transaction_id
  end
end
