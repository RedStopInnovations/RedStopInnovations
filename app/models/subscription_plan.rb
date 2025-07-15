# == Schema Information
#
# Table name: subscription_plans
#
#  id                :integer          not null, primary key
#  name              :string
#  description       :string
#  appointment_price :decimal(10, 2)   default(0.0)
#  sms_price         :decimal(10, 2)   default(0.0)
#  routes_price      :decimal(10, 2)   default(0.0)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class SubscriptionPlan < ApplicationRecord
  has_many :subscriptions
end
