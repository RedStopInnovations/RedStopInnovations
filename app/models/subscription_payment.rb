# == Schema Information
#
# Table name: subscription_payments
#
#  id               :integer          not null, primary key
#  payment_date     :datetime
#  amount           :decimal(10, 2)   default(0.0)
#  stripe_charge_id :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  business_id      :integer
#  payment_type     :string
#  invoice_id       :integer
#
# Indexes
#
#  index_subscription_payments_on_invoice_id  (invoice_id)
#

class SubscriptionPayment < ApplicationRecord
  PAYMENT_TYPES = [
    PAYMENT_TYPE_DIRECT_DEPOSIT = 'Direct deposit',
    PAYMENT_TYPE_CREDIT_CARD = 'Credit card'
  ]

  MANUAL_PAYMENT_TYPES = [
    PAYMENT_TYPE_DIRECT_DEPOSIT
  ]
  belongs_to :business_invoice, class_name: 'BusinessInvoice', foreign_key: :invoice_id
  belongs_to :business

  validates_presence_of :payment_date, :invoice_id
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_type, presence: true, inclusion: { in: PAYMENT_TYPES }

  after_commit on: [:create, :update] do
    unless business_invoice.paid?
      if amount >= business_invoice.amount
        business_invoice.mark_paid
      end
    end
  end

  def editable?
    payment_type != PAYMENT_TYPE_CREDIT_CARD
  end
end
