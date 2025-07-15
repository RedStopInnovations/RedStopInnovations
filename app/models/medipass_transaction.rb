# == Schema Information
#
# Table name: medipass_transactions
#
#  id             :integer          not null, primary key
#  invoice_id     :integer          not null
#  payment_id     :integer
#  transaction_id :string           not null
#  requested_at   :datetime
#  approved_at    :datetime
#  cancelled_at   :datetime
#  status         :string           not null
#  amount_benefit :decimal(10, 2)   default(0.0)
#  amount_gap     :decimal(10, 2)   default(0.0)
#  token          :string           not null
#  created_at     :datetime
#
# Indexes
#
#  index_medipass_transactions_on_invoice_id  (invoice_id)
#  index_medipass_transactions_on_payment_id  (payment_id)
#

class MedipassTransaction < ApplicationRecord
  STATUS_PENDING   = 'pending'
  STATUS_COMPLETED = 'completed'
  STATUS_CANCELLED = 'cancelled'
  STATUS_ERRORED   = 'errored'

  belongs_to :invoice, -> { with_deleted }

  validates_presence_of :transaction_id,
                        :amount_benefit,
                        :amount_gap,
                        :token,
                        :requested_at

  scope :pending, -> { where status: STATUS_PENDING }

  def pending?
    status == STATUS_PENDING
  end

  def completed?
    status == STATUS_COMPLETED
  end
end
