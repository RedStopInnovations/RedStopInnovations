FactoryBot.define do
  factory :treatment do
    name { FFaker::Lorem.word }
    status { ['Draft', 'Final'].sample }
    sections { [
      {
        name: "Section 1",
        questions: [
          {
            name: 'Question 1.1',
            type: 'Text',
            answer: {
              content: FFaker::Lorem.phrase
            }
          }
        ]
      },
      {
        name: "Section 2",
        questions: [
          {
            name: 'Question 2.1',
            type: 'Text',
            answer: {
              content: FFaker::Lorem.phrase
            }
          }
        ]
      }
    ] }

    trait :draft do
      status { 'Draft' }
    end
    trait :final do
      status { 'Final' }
    end
  end
end
