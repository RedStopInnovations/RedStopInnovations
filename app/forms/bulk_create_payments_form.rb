class BulkCreatePaymentsForm < BaseForm
  class InvoicePayment
    include Virtus.model
    include ActiveModel::Model

    attribute :invoice_id, String
    attribute :payment_method, String
    attribute :payment_date, String

    validates_presence_of :invoice_id, :payment_method, :payment_date

    validates :payment_method,
              presence: true,
              inclusion: {
                in: [
                  PaymentType::DIRECT_DEPOSIT,
                  PaymentType::CASH,
                  PaymentType::CHEQUE,
                  PaymentType::WORKCOVER,
                  PaymentType::OTHER,
                ]
              }

    validates_date :payment_date

    validate do
      unless errors.key?(:invoice_id)
        invoice = Invoice.find_by(id: invoice_id)
        if !invoice
          errors.add :invoice_id, 'does not exist'
        else
          if invoice.paid?
            errors.add :invoice_id, 'is not in payable state'
          end
        end
      end
    end
  end

  attr_accessor :business

  attribute :payments, Array[InvoicePayment]

  validate do
    unless errors.key?(:payments)
      if payments.count > App::MAX_BULK_CREATE_PAYMENTS
        errors.add(:base, "Number of invoices must not exceed #{App::MAX_BULK_CREATE_PAYMENTS}")
      end
    end

    payments.each_with_index do |payment, index|
      payment.validate
      if !payment.valid?
        errors.add(:base, "Payment ##{index + 1} is invalid: #{payment.errors.full_messages.join('; ')}")
      end
    end
  end
end