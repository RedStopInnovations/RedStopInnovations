FactoryBot.define do
  factory :task do
    name { FFaker::Lorem.words(4).join(' ') }
    priority { ['High', 'Medium', 'Low'].sample }
    description { FFaker::Lorem.paragraph }
    is_invoice_required { [true, false].sample }
    # due_on

    after :build do |task|
      task.users << task.owner
    end
  end
end
