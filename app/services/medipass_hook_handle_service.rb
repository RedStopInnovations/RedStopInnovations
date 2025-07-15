class MedipassHookHandleService
  attr_reader :hook_params

  def call(hook_params)
    @hook_params = hook_params
    event = hook_params['event']

    case event
    when 'memberApprovedInvoice', 'memberRejectedInvoice', 'medipassAutoCancelledInvoice'
      process_invoice_approval_event
    end
  end

  private

  def process_invoice_approval_event
    if hook_params[:transaction]
      txn_data = hook_params[:transaction]
      medipass_txn = MedipassTransaction.pending.find_by(
        transaction_id: txn_data['_id']
      )

      if medipass_txn
        ApplicationRecord.transaction do
          medipass_txn.update_column :status, txn_data['status']

          invoice = medipass_txn.invoice

          if medipass_txn.completed? && invoice
            business = invoice.business
            payment = Payment.create!(
              business: business,
              patient: invoice.patient,
              eftpos: medipass_txn.amount_gap,
              hicaps: medipass_txn.amount_benefit,
              payment_date: Date.current,
              editable: false
            )

            PaymentAllocation.create!(
              payment: payment,
              invoice: invoice,
              amount: payment.amount
            )

            invoice.update_outstanding_amount
            medipass_txn.update_columns(
              approved_at: txn_data['approved'],
              payment_id: payment.id
            )
          end
        end
      end
    end
  end
end
