FactoryBot.define do
  factory :user do
    email { FFaker::Internet.safe_email }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    password { '123Abc!@#' }
    role { 'administrator' }
    timezone { 'Australia/Brisbane' }

    trait :as_practitioner do
      is_practitioner { true }
    end

    trait :as_non_practitioner do
      is_practitioner { false }
    end

    trait :with_administrator_role do
      role { 'administrator' }
    end

    trait :with_supervisor_role do
      role { 'supervisor' }
    end

    trait :with_practitioner_role do
      role { 'practitioner' }
    end

    trait :with_receptionist_role do
      role { 'receptionist' }
    end

    after :build do |user|
      user.business = FactoryBot.create :business unless user.business
    end

    after :create do |user|
      if user.is_practitioner?
        FactoryBot.create :practitioner, user: user, business: user.business
      end
    end
  end
end
