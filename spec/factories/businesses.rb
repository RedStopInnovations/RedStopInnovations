FactoryBot.define do
  factory :business do
    name  { FFaker::Company.name }
    phone { FFaker::PhoneNumberAU.phone_number }
    mobile { FFaker::PhoneNumberAU.mobile_phone_number }
    website { FFaker::Internet.http_url }
    fax { FFaker::PhoneNumberAU.phone_number }
    email { FFaker::Internet.safe_email }
    address1 { FFaker::Address.street_address }
    address2 { FFaker::Address.secondary_address }
    city { FFaker::AddressAU.city }
    state { FFaker::AddressAU.state_abbr }
    postcode { FFaker::AddressAU.postcode }
    country { 'AU' }
    latitude { FFaker::Geolocation.lat }
    longitude { FFaker::Geolocation.lng }
    bank_name { 'World Bank' }
    bank_branch_number { '123' }
    bank_account_name { 'My account' }
    bank_account_number { '123' }
    abn { 'ABN123456' }

    after :create do |business|
      FactoryBot.create :subscription, business: business
    end
  end
end
