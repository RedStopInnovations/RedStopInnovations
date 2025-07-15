FactoryBot.define do
  factory :referral do
    referrer_business_name { FFaker::Company.name }
    referrer_name { FFaker::Name.name }
    referrer_email { FFaker::Internet.safe_email }
    referrer_phone { FFaker::PhoneNumberAU.phone_number }

    professions { [%w[Physiotherapist Podiatrist Chiropractor].sample] }
    availability_type_id { [1, 4, 5].sample }

    status { ['Pending', 'Rejected', 'Approved'] }
    type { ['general', 'dva', 'ndis', 'strc'].sample }
    medical_note { FFaker::Lorem.paragraph }
    priority { [nil, 'Urgent', 'Normal'].sample }

    patient_attrs {
      {
        first_name: FFaker::Name.first_name,
        last_name: FFaker::Name.last_name,
        dob: '1980-01-01',
        address1: FFaker::Address.street_address,
        city: FFaker::AddressAU.city,
        state: FFaker::AddressAU.state_abbr,
        postcode: FFaker::AddressAU.postcode,
        country: 'AU',
        phone: FFaker::PhoneNumberAU.phone_number,
        mobile: FFaker::PhoneNumberAU.mobile_phone_number
      }
    }
  end
end
