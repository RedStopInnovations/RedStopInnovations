# == Schema Information
#
# Table name: subscriptions
#
#  id                   :integer          not null, primary key
#  subscription_plan_id :integer
#  business_id          :integer
#  trial_start          :datetime
#  trial_end            :datetime
#  billing_start        :datetime
#  billing_end          :datetime
#  status               :string
#  stripe_customer_id   :string
#  card_last4           :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  email                :string
#  admin_settings       :jsonb
#
# Indexes
#
#  index_subscriptions_on_business_id           (business_id)
#  index_subscriptions_on_subscription_plan_id  (subscription_plan_id)
#

class Subscription < ApplicationRecord
  include RansackAuthorization::Subscription
  DEFAULT_ADMIN_SETTINGS = {
    auto_send_invoice: false,
    auto_payment: false,
    auto_payment_delay: nil,
    notify_new_invoice: true,
  }

  belongs_to :business
  belongs_to :subscription_plan, optional: false

  has_many :subscription_billings

  has_one :subscription_admin_setting

  validates_presence_of :subscription_plan_id

  store_accessor :admin_settings,
                 :auto_send_invoice,
                 :auto_payment,
                 :auto_payment_delay,
                 :notify_new_invoice

  def remaining_trial_days
    now = Time.current
    if trial_end > now
      (trial_end.to_date - now.to_date).to_i
    else
      0
    end
  end

  def on_trial?
    trial_end > Time.current
  end

  def credit_card_added?
    stripe_customer_id.present?
  end

  def last_pending_invoice
    business.business_invoices.order(issue_date: :desc).pending.not_deleted.first
  end
end
