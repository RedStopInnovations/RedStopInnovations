FactoryBot.define do
  factory :subscription do
    trial_start { FFaker::Time.datetime }
    trial_end { FFaker::Time.datetime }
    billing_start { FFaker::Time.datetime }
    billing_end { FFaker::Time.datetime }

    after :build do |subscription|
      subscription.subscription_plan = FactoryBot.create :subscription_plan
    end
  end
end
