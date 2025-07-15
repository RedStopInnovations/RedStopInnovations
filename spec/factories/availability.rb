FactoryBot.define do
  factory :availability do
    max_appointment { 10 }
    service_radius { 25 }
    allow_online_bookings { [true, false].sample }
    availability_type_id { [1, 4, 5].sample }
    address1 { FFaker::Address.street_address }
    address2 { FFaker::Address.secondary_address }
    city { FFaker::AddressAU.city }
    state { FFaker::AddressAU.state_abbr }
    postcode { FFaker::AddressAU.postcode }
    country { 'AU' }
    latitude { FFaker::Geolocation.lat }
    longitude { FFaker::Geolocation.lng }

    trait :type_home_visit do
      availability_type_id { 1 }
    end

    trait :type_facility do
      availability_type_id { 4 }
    end

    trait :type_non_billable do
      availability_type_id { 5 }
    end

    trait :type_group_appointment do
      availability_type_id { 6 }
    end
  end
end
