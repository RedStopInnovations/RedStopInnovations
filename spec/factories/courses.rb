FactoryBot.define do
  factory :course do
    title { FFaker::Lorem.sentence }
    video_url { FFaker::Internet.http_url }
    presenter_full_name { FFaker::Name.name }
    course_duration { '60 minutes' }
    cpd_points { '100' }
    description { FFaker::Lorem.paragraph }
    reflection_answer { FFaker::Lorem.paragraph }
    profession_tags { %w[Physiotherapist Podiatrist Massage Chiropractor].sample(2) }
    seo_page_title { FFaker::Lorem.sentence }
    seo_description { FFaker::Lorem.sentence }
  end
end
