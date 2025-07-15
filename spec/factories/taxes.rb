FactoryBot.define do
  factory :tax do
    name { FFaker::Lorem.words(4).join(' ') }
    rate { rand(1..20) }
  end
end
