class UpdatePaymentForm < BaseForm
  attr_accessor :business

  class PaymentAllocation
    include Virtus.model
    include ActiveModel::Model
    attribute :invoice_id, Integer
    attribute :amount, Float

    validates :invoice_id, presence: true
    validates :amount,
              presence: true,
              numericality: { greater_than: 0 }

    validate do
      unless errors.key?(:invoice_id) || errors.key?(:amount)
        invoice = Invoice.with_deleted.find_by(id: invoice_id)
        if invoice
          if invoice.amount.to_f < amount
            errors.add(:amount, 'is exceed the invoice outstanding.')
          end
        else
          errors.add(:invoice_id, 'is not existing.')
        end
      end
    end
  end

  attribute :payment_date, Date
  attribute :payment_allocations, Array[PaymentAllocation]

  attribute :cash, Float
  attribute :medicare, Float
  attribute :workcover, Float
  attribute :dva, Float
  attribute :direct_deposit, Float
  attribute :cheque, Float
  attribute :other, Float

 validates :cash, :medicare, :workcover, :dva, :direct_deposit, :cheque, :other,
            numericality: {
              greater_than: 0,
              message: 'amount must be greater than 0',
              allow_nil: true,
              allow_blank: true
            },
            allow_nil: true,
            allow_blank: true

  validates :payment_date, presence: true

  validate do
    payment_allocations.each do |alloc|
      unless alloc.valid?
        errors.add(
          :base,
          "Some payment allocation is not valid: #{alloc.errors.full_messages.first}"
        )
      end

      if alloc.invoice_id.present? && !business.invoices.where(id: alloc.invoice_id).exists?
        errors.add(
          :base,
          "Some payment allocation is not valid: The invoice ID is not existing."
        )
      end
    end
  end

  validate do
    total_allocated = 0
    payment_allocations.each do |alloc|
      next unless alloc.valid?
      total_allocated += alloc.amount if alloc.amount
    end
    if total_allocated > total_amount
      errors.add(:base, 'Payment allocations exceed the total amount.')
    end
  end

  validate do
    unless total_amount > 0
      errors.add(:base, 'Total paid amount must be large than 0.')
    end
  end

  def total_amount
    [cash, medicare, workcover, dva, direct_deposit, cheque, other].compact.sum
  end
end
