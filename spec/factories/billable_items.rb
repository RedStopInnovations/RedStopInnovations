FactoryBot.define do
  factory :billable_item do
    name { FFaker::Lorem.words(4).join(' ') }
    description { FFaker::Lorem.sentence }
    item_number { rand(1000000..9000000).to_s }
    price { rand(50..300) }
  end
end
