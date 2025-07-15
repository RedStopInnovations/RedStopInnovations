if SubscriptionPlan.where(name: 'Public').exists?
  puts "Public subscription plan already exists, skipping creation."
else
  SubscriptionPlan.create!(
    name: 'Public',
    appointment_price: 0,
    sms_price: 0.1,
    routes_price: 0
  )

  puts "Public subscription plan created"
end


if SubscriptionPlan.where(name: 'Private').exists?
  puts "Premium subscription plan already exists, skipping creation."
else

  SubscriptionPlan.create!(
    name: 'Private',
    appointment_price: 0.25,
    sms_price: 0.1,
    routes_price: 0
  )

  puts "Private subscription plan created"
end
