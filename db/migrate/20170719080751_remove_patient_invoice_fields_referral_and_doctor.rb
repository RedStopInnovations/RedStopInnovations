class RemovePatientInvoiceFieldsReferralAndDoctor < ActiveRecord::Migration[5.0]
  def change
    remove_column :patients, :referral_info, :string
    remove_column :patients, :doctor, :string
    remove_column :patients, :reference, :string
    remove_column :patients, :invoice_to, :string
    remove_column :patients, :invoice_email, :string
    remove_column :patients, :invoice_extra, :string
  end
end
