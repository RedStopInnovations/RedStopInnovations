# == Schema Information
#
# Table name: business_invoice_items
#
#  id                  :integer          not null, primary key
#  business_invoice_id :integer
#  unit_name           :string
#  unit_price          :decimal(10, 2)   default(0.0)
#  quantity            :integer
#  amount              :decimal(10, 2)   default(0.0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_business_invoice_items_on_business_invoice_id  (business_invoice_id)
#

class BusinessInvoiceItem < ApplicationRecord
  belongs_to :business_invoice, inverse_of: :items
  validates_presence_of :unit_name, :business_invoice, :quantity, :unit_price

  validates :quantity,
            presence: true,
            numericality: { only_integer: true, greater_than: 0 }

  before_save :assign_total_amount

  private

  def assign_total_amount
    self.amount = quantity * unit_price
  end
end
