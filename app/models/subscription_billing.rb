# == Schema Information
#
# Table name: subscription_billings
#
#  id                         :integer          not null, primary key
#  subscription_id            :integer
#  appointment_id             :integer
#  first_invoice_date         :datetime
#  billing_type               :string
#  subscription_price_on_date :decimal(10, 2)   default(0.0)
#  discount_applied           :decimal(10, 2)   default(0.0)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  business_invoice_id        :integer
#  quantity                   :integer
#  trigger_type               :string
#  triggers                   :text
#  description                :text
#
# Indexes
#
#  index_subscription_billings_on_appointment_id   (appointment_id)
#  index_subscription_billings_on_subscription_id  (subscription_id)
#

class SubscriptionBilling < ApplicationRecord
  serialize :triggers, type: Array
  belongs_to :subscription
  belongs_to :appointment, -> { with_deleted }
  belongs_to :business_invoice

  TRIGGER_TYPES = [
    TRIGGER_TYPE_COMPLETED              = 'COMPLETED',
    TRIGGER_TYPE_INVOICED               = 'INVOICED',
    TRIGGER_TYPE_TREATMENT_NOTE_CREATED = 'TREATMENT_NOTE_CREATED',
    TRIGGER_TYPE_OCCURRED               = 'OCCURRED'
  ]

  BILLING_TYPES = [
    "APPOINTMENT",
    "SMS",
    "ROUTES"
  ]
end
