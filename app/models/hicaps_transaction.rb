# == Schema Information
#
# Table name: hicaps_transactions
#
#  id             :integer          not null, primary key
#  payment_id     :integer          not null
#  transaction_id :string           not null
#  requested_at   :datetime
#  approved_at    :datetime
#  status         :string
#  amount_benefit :float
#  amount_gap     :float
#  created_at     :datetime
#
# Indexes
#
#  index_hicaps_transactions_on_payment_id  (payment_id)
#

class HicapsTransaction < ApplicationRecord
  STATUS_PENDING   = 'pending'
  STATUS_COMPLETED = 'completed'
  STATUS_CANCELLED = 'cancelled'
  STATUS_ERRORED   = 'errored'

  belongs_to :payment

  validates_presence_of :payment, :transaction_id

  scope :pending, -> { where status: STATUS_PENDING }

  def pending?
    status == STATUS_PENDING
  end

  def completed?
    status == STATUS_COMPLETED
  end
end
