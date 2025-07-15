FactoryBot.define do
  factory :contact do
    business_name  { FFaker::Company.name }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    email { FFaker::Internet.safe_email }
    address1 { FFaker::Address.street_address }
    address2 { FFaker::Address.secondary_address }
    city { FFaker::AddressAU.city }
    state { FFaker::AddressAU.state_abbr }
    postcode { FFaker::AddressAU.postcode }
    country { 'AU' }
    latitude { FFaker::Geolocation.lat }
    longitude { FFaker::Geolocation.lng }
    phone { FFaker::PhoneNumberAU.phone_number }
    mobile { FFaker::PhoneNumberAU.mobile_phone_number }
  end
end
