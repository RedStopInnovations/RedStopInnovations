FactoryBot.define do
  factory :treatment_template do
    name { FFaker::Lorem.word }
    template_sections { [
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
  end
end
