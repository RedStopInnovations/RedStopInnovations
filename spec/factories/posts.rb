FactoryBot.define do
  factory :post do
    title { FFaker::Lorem.sentence }
    summary { FFaker::Lorem.sentence }
    content { FFaker::Lorem.paragraph }
    thumbnail { Rack::Test::UploadedFile.new "#{Rails.root}/spec/fixtures/images/sample-grey-bg.jpg", "image/jpg" }

    trait :as_published do
      published { true }
    end
  end
end
