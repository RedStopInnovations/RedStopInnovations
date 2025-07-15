FactoryBot.define do
  factory :case_type do
    title { FFaker::Lorem.words(3).join(' ') }
    description { FFaker::Lorem.paragraph }
  end
end
