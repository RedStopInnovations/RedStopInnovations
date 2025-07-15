FactoryBot.define do
  factory :trigger_word do
    text { FFaker::Lorem.word }
  end
end
