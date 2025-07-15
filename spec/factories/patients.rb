FactoryBot.define do
  factory :patient do
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

    gender { ['Male', 'Female', 'Undisclosed'].sample }

    dob { '1980-01-01' }

    trait :with_medicare_details do
      medicare_card_number { 10000000.to_s }
      medicare_card_irn { (1..10).to_a.sample }
      medicare_referrer_name { FFaker::Name }
      medicare_referrer_provider_number { 'Xyz123456' }
      medicare_referral_date { '2003-11-10' }
    end
  end
end
