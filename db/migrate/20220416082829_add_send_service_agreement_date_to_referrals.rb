class AddSendServiceAgreementDateToReferrals < ActiveRecord::Migration[6.1]
  def change
    add_column :referrals, :send_service_agreement_date, :date
  end
end
