FactoryBot.define do
  factory :appointment_type do
    name { 'Initial consultation' }
    description { FFaker::Lorem.paragraph }
    duration { [30, 50, 60].sample }
    availability_type_id { [1, 2, 4].sample }

    trait :home_visit do
      availability_type_id { 1 }
    end

    trait :facility do
      availability_type_id { 4 }
    end

    trait :group_appointment do
      availability_type_id { 6 }
    end
  end
end
