class UpdatePatientCardService
  attr_reader :patient, :business, :token
  # @param patient Patient
  # @param token   String The stripe token
  def call(business, patient, token)
    @business = business
    @patient = patient
    @token = token
    result = OpenStruct.new(success: true, error: nil)

    error = nil

    if !business.stripe_payment_available?
      error = 'Stripe payment is not available for your company account'
    end

    if error
      result.success = false
      result.error = error
    else
      business_stripe_account_id = business.stripe_account.account_id
      local_stripe_cust = patient.stripe_customer

      begin
        if local_stripe_cust
          # Make sure customer is exists
          begin
            stripe_cust = Stripe::Customer.retrieve(
              local_stripe_cust.stripe_customer_id,
              stripe_account: business_stripe_account_id
            )
          rescue Stripe::InvalidRequestError => e
            Sentry.capture_exception(e)
          end
        else
          local_stripe_cust = PatientStripeCustomer.new(
            patient: patient
          )
        end

        if stripe_cust.nil?
          stripe_token = Stripe::Token.retrieve token
          stripe_cust = Stripe::Customer.create(
            {
              description: stripe_customer_description,
              email: patient.email,
              source: token
            },
            {
              stripe_account: business_stripe_account_id
            }
          )
        else
          stripe_cust.source = token
          stripe_cust.save
        end

        local_stripe_cust.assign_attributes(
          stripe_customer_id: stripe_cust.id,
          card_last4: stripe_cust.sources.first.last4,
          stripe_owner_account_id: business_stripe_account_id
        )
        local_stripe_cust.save!
        stripe_cust.save

        result.success = true
        result.stripe_customer = local_stripe_cust

        result

      rescue Stripe::CardError => e
        Sentry.capture_exception(e)
        result.success = false
        result.error = "Card error: #{ e.message }"
      rescue Stripe::StripeError => e
        Sentry.capture_exception(e)
        result.success = false
        result.error = 'Could not verify the card.'
      end
    end

    result
  end

  private

  def stripe_customer_description
    "#{patient.full_name}. Patient of #{business.name}."
  end
end
