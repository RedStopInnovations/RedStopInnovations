class CreateMedipassQuote
  attr_reader :invoice, :medipass_member_id

  def call(invoice, medipass_member_id)
    @invoice = invoice
    @medipass_member_id = medipass_member_id
    medipass_account = invoice.business.medipass_account
    raw_transaction = Medipass::Quote.create(
      medipass_account.api_key,
      build_transaction_claim_body
    )
    quote = store_invoice_quote(raw_transaction)
    quote
  end

  private

  def store_invoice_quote(raw_transaction)
    MedipassQuote.create!(
      invoice: invoice,
      member_id: raw_transaction['member']['_id'],
      transaction_id: raw_transaction['_id'],
      amount_gap: (raw_transaction['amountGap'].to_i) / 100,
      amount_benefit: (raw_transaction['amountBenefit'].to_i) / 100,
      amount_fee: (raw_transaction['amountFee'].to_i) / 100,
      amount_charged: (raw_transaction['amountCharged'].to_i) / 100,
      amount_discount: (raw_transaction['amountDiscount'].to_i) / 100,
    )
  end

  def build_transaction_claim_body
    params = {}
    params[:serviceDate] = invoice.appointment.start_time.strftime('%Y-%m-%d')
    params[:providerNumber] = invoice.provider_number
    params[:memberId] = medipass_member_id

    params[:claimItems] = []

    invoice.items.billable_item.each do |invoice_item|
      params[:claimItems] << {
        itemCode: invoice_item.item_number.to_s,
        chargeAmount: invoice_item.amount.to_s
      }
    end
    params
  end
end
