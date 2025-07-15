FactoryBot.define do
  factory :product do
    name { FFaker::Lorem.words(4).join(' ') }
    item_code { "P-#{rand(1000000..9000000)}" }
    price { rand(50..300) }
    serial_number { "S#{rand(1000000..9000000)}" }
  end
end
