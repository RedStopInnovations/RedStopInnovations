json.payment_methods do
  json.credit_card do
    if @patient.stripe_customer
      json.last4 @patient.stripe_customer.card_last4
    end
  end

  json.medicare @patient.medicare_details
  json.dva @patient.dva_details
  json.ndis @patient.ndis_details
  json.hcp @patient.hcp_details
  json.hih @patient.hih_details
  json.hi @patient.hi_details
  json.strc @patient.strc_details
end