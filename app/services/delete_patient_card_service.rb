class DeletePatientCardService
  def call(business, patient)
    result = OpenStruct.new(success: true)
    error = nil

    if patient.stripe_customer.nil?
      error = 'The client card is not found or has been already deleted.'
    end

    if error
      result.error = error
      result.success = false
    else

      if business.stripe_account
        begin
          stripe_cust = Stripe::Customer.retrieve(
            patient.stripe_customer.stripe_customer_id,
            stripe_account: business.stripe_account.account_id
          )
          stripe_cust.delete
        rescue Stripe::InvalidRequestError => e
          Sentry.capture_exception(e)
        end
      end

      # Ignore Stripe customer not found error. We still delete the local record.
      patient.stripe_customer.destroy
      result.success = true
    end

    result
  end
end
