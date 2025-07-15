# == Schema Information
#
# Table name: business_invoices
#
#  id                      :integer          not null, primary key
#  business_id             :integer
#  issue_date              :datetime
#  subtotal                :decimal(10, 2)   default(0.0)
#  tax                     :decimal(10, 2)   default(0.0)
#  discount                :decimal(10, 2)   default(0.0)
#  amount                  :decimal(10, 2)   default(0.0)
#  payment_status          :string
#  date_closed             :datetime
#  invoice_number          :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  notes                   :text
#  subscription_payment_id :integer
#  last_sent_at            :datetime
#  deleted_at              :datetime
#  billing_start_date      :datetime
#  billing_end_date        :datetime
#
# Indexes
#
#  index_business_invoices_on_business_id  (business_id)
#

class BusinessInvoice < ApplicationRecord
  include RansackAuthorization::BusinessInvoice
  belongs_to :business
  has_many :subscription_payments, foreign_key: :invoice_id, dependent: :delete_all

  has_many :items,
           class_name: 'BusinessInvoiceItem',
           inverse_of: :business_invoice,
           dependent: :delete_all
  has_many :subscription_billings

  validates :tax, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }

  validates :discount, numericality: {
    greater_than_or_equal_to: 0
  }

  accepts_nested_attributes_for :items,
    reject_if: -> attrs { attrs[:unit_name].blank? && attrs[:quantity].blank? && attrs[:unit_price].blank? },
    allow_destroy: true

  validates_presence_of :business, :issue_date

  before_create :generate_invoice_number
  after_commit :update_subtotal_and_amount, on: [:create, :update]
  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :pending, -> { where(payment_status: 'pending') }

  PAYMENT_STATUS_TYPES = [
    "pending",
    "on_hold",
    "paid"
  ]
  UNIT_NAME_TYPES = [
    "APPOINTMENT",
    "SMS",
    "ROUTES",
    "MINIMUM SUBSCRIPTION FEE"
  ]

  def pending?
    payment_status == 'pending'
  end

  def paid?
    payment_status == 'paid'
  end

  def mark_paid
    update_column :payment_status, 'paid'
  end

  private

  def generate_invoice_number
    business_invoices_count = BusinessInvoice.count
    # Invoice numbers has at least 5 characters and leading zeros.
    self.invoice_number = (business_invoices_count + 1).to_s.rjust 5, '0'
  end

  def update_subtotal_and_amount
    _subtotal = 0
    items.each do |item|
      _subtotal += (item.quantity * item.unit_price)
    end

    _total_amount = _subtotal

    # Add GST
    _total_amount += 0.1 * _subtotal

    _total_amount = _total_amount - discount

    if _total_amount < 0
      _total_amount = 0
    end

    update_columns(
      subtotal: _subtotal,
      amount: _total_amount.round(2)
    )
  end
end
