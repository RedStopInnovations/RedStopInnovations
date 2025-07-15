class MedipassPaymentService

  class Exception < StandardError; end

  attr_reader :invoice,
              :business,
              :verify_token

  def call(invoice)
    @invoice = invoice
    @business = @invoice.business
    @verify_token = SecureRandom::hex(16)

    ensure_invoice_info
    ensure_invoice_has_claimable_items_only

    ActiveRecord::Base.transaction do

      medipass_transaction = create_medipass_transaction(
        build_transaction_claim_body(discovery_patient_medipass_member_id)
      )

      store_medipass_transaction(medipass_transaction)
    end
  end

  private

  def ensure_invoice_info
    # Check no pending transaction requested
    if MedipassTransaction.pending.exists?(invoice_id: invoice.id)
      raise Exception,
            "A Medipass payment has already been requested for invoice ##{invoice.invoice_number}."
    end

    unless invoice.payable?
      raise Exception,
            "The invoice ##{invoice.invoice_number} is not in payable state."
    end

    unless invoice.appointment
      raise Exception,
            "The invoice ##{invoice.invoice_number} is not attached to an appointment."
    end

    unless invoice.items.size > 0
      raise Exception, "The invoice ##{invoice.invoice_number} has no any items."
    end

    unless invoice.practitioner.medicare?
      raise Exception, "The practitioner's medicare provider number is not set."
    end
  end

  def ensure_patient_info
    unless invoice.patient.dob.present?
      raise Exception, "The client missing date of birth. We could not find the Medipass member info."
    end
  end

  def ensure_invoice_has_claimable_items_only
    has_non_claimable_item = invoice.items.billable_item.any? do |invoice_item|
      !invoice_item.invoiceable.health_insurance_rebate?
    end
    if has_non_claimable_item
      raise Exception,
            "The invoice ##{invoice.invoice_number} contains claimable and non claimable items,"\
            "this feature is not yet available on Medipass. "\
            "Please remove non claimable items from invoice to process payment."
    end
  end

  def discovery_patient_medipass_member_id
    res = Medipass::Member.discovery build_medipass_member_discovery_params
    return res['_id']
    rescue Medipass::ApiException => e
      raise Exception, 'Sorry, the Medipass member info was not found for the client.'
  end

  def create_medipass_transaction(claim_body)
    Medipass::Transaction.create(
      business.medipass_account.api_key,
      claim_body
    )
    rescue Medipass::ApiException => e
      raise Exception, e.message
  end

  def build_transaction_claim_body(medipass_member_id)
    params = {}
    params[:serviceDate] = invoice.appointment.start_time.strftime('%Y-%m-%d')
    params[:providerNumber] = invoice.provider_number
    params[:memberId] = medipass_member_id

    webhook_url = "#{ENV['BASE_URL']}/_hooks/medipass?token=#{verify_token}"
    params[:webhooks] = [
      {
        method: 'POST',
        url: webhook_url,
        event: 'memberApprovedInvoice'
      },
      {
        method: 'POST',
        url: webhook_url,
        event: 'memberRejectedInvoice'
      },
      {
        method: 'POST',
        url: webhook_url,
        event: 'medipassAutoCancelledInvoice'
      }
    ]
    params[:claimItems] = []

    invoice.items.billable_item.each do |invoice_item|
      params[:claimItems] << {
        itemCode: invoice_item.item_number.to_s,
        chargeAmount: invoice_item.amount.to_s
      }
    end
    params
  end

  def build_medipass_member_discovery_params
    patient = invoice.patient

    attrs_map = {
      first_name: :firstName,
      last_name: :lastName,
    }
    params = {}
    attrs_map.each do |k, v|
      params[v] = patient[k] if patient[k].present?
    end

    if patient.dob?
      params[:dobString] = patient.dob.try(:strftime, '%Y-%m-%d')
    end

    params
  end

  def store_medipass_transaction(transaction)
    MedipassTransaction.create!(
      invoice_id: @invoice.id,
      transaction_id: transaction['_id'],
      status: transaction['status'],
      amount_benefit: (transaction['amountBenefit'].to_f) / 100,
      amount_gap: (transaction['amountGap'].to_f) / 100,
      requested_at: Time.current,
      token: verify_token
    )
  end
end
