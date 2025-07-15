# == Schema Information
#
# Table name: subscription_discounts
#
#  id            :integer          not null, primary key
#  name          :string
#  discount_type :string
#  business_id   :integer
#  amount        :decimal(10, 2)   default(0.0)
#  from_date     :datetime
#  end_date      :datetime
#  expired       :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_subscription_discounts_on_business_id  (business_id)
#

class SubscriptionDiscount < ApplicationRecord
  belongs_to :business
  
  validates_presence_of :business, :discount_type, :from_date, :end_date
  validates :amount, presence: true, numericality: { greater_than: 0}
  
  DISCOUNT_TYPES = [
    "on_subscription",
    "credit_on_invoice"
  ]
end
