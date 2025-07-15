FactoryBot.define do
  factory :practitioner do
    profession { %w[Physiotherapist Podiatrist Chiropractor].sample }
    ahpra { 'ABC123456' }
    medicare { 'ABC123456' }
    phone { FFaker::PhoneNumberAU.phone_number }
    mobile { FFaker::PhoneNumberAU.mobile_phone_number }
    website { FFaker::Internet.http_url }
    email { FFaker::Internet.safe_email }
    address1 { FFaker::Address.street_address }
    address2 { FFaker::Address.secondary_address }
    city { FFaker::AddressAU.city }
    state { FFaker::AddressAU.state_abbr }
    postcode { FFaker::AddressAU.postcode }
    country { 'AU' }
    latitude { FFaker::Geolocation.lat }
    longitude { FFaker::Geolocation.lng }
    color { 'green' }
    summary { FFaker::Lorem.paragraph }
    education { FFaker::Education.degree }
    service_description { FFaker::Lorem.paragraph }
    availability { FFaker::Lorem.paragraph }
    active { true }
    public_profile { true }
    approved { true }
  end
end
