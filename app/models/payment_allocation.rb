# == Schema Information
#
# Table name: payment_allocations
#
#  id         :integer          not null, primary key
#  payment_id :integer          not null
#  invoice_id :integer          not null
#  amount     :decimal(10, 2)   not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_payment_allocations_on_invoice_id  (invoice_id)
#  index_payment_allocations_on_payment_id  (payment_id)
#

class PaymentAllocation < ApplicationRecord
  belongs_to :invoice, -> { with_deleted }
  belongs_to :payment, -> { with_deleted }

  validates :amount,
            presence: true,
            numericality: { greater_than: 0 }
end
