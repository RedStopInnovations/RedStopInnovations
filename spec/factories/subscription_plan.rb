FactoryBot.define do
  factory :subscription_plan do
    name { FFaker::Name.name }
    description { FFaker::Lorem.sentence }
    appointment_price { 3 }
    sms_price { 0.1 }
    routes_price { 0.1 }
  end
end
