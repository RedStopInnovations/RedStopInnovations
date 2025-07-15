class CreateSubscription
  def call(subscription_plan_id, business_id)
    trial_start = Time.current
    ActiveRecord::Base.transaction do
      trial_end = trial_start + App::SUBSCRIPTION_TRIAL_DAYS.days
      billing_start = trial_end + 1.day
      billing_end = billing_start + 30.days
      subscription = Subscription.create!(
        subscription_plan_id: subscription_plan_id,
        business_id: business_id,
        trial_start: trial_start,
        trial_end: trial_end,
        billing_start: billing_start,
        billing_end: billing_end,
        status: 'active',
        admin_settings: Subscription::DEFAULT_ADMIN_SETTINGS
      )
    end
  end
end
