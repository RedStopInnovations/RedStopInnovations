describe Trigger::TriggerCategoryCalculator do
  let!(:current_user) { FactoryBot.create(:user) }
  let!(:current_business) { current_user.business }
  let!(:patient1) { FactoryBot.create(:patient, business: current_business) }
  let!(:patient2) { FactoryBot.create(:patient, business: current_business) }
  let!(:treatment_template) do
    FactoryBot.create(:treatment_template, business: current_business)
  end

  let!(:treatment_note1) do
    FactoryBot.create(
      :treatment,
      patient: patient1,
      author: current_user,
      treatment_template: treatment_template,
      sections: [
        {
          name: "Section 1",
          questions: [
            {
              name: 'Question 1.1',
              type: 'Text',
              answer: {
                content: 'Something not right'
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
                content: 'Something right'
              }
            }
          ]
        }
      ]
    )
  end

  let!(:treatment_note2) do
    FactoryBot.create(
      :treatment,
      patient: patient2,
      author: current_user,
      treatment_template: treatment_template,
      sections: [
        {
          name: "Section 1",
          questions: [
            {
              name: 'Question 1.1',
              type: 'Text',
              answer: {
                content: 'Something went wrong'
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
                content: 'Ok'
              }
            }
          ]
        }
      ]
    )
  end

  let!(:trigger_category1) do
    cat = FactoryBot.create(:trigger_category, business: current_business)
    cat.words << FactoryBot.build(
      :trigger_word,
      text: 'something'
    )

    cat.words << FactoryBot.build(
      :trigger_word,
      text: 'not'
    )

    cat
  end

  let!(:trigger_category2) do
    cat = FactoryBot.create(:trigger_category, business: current_business)
    cat.words << FactoryBot.build(
      :trigger_word,
      text: 'right'
    )
    cat
  end

  let!(:trigger_category3) do
    cat = FactoryBot.create(:trigger_category, business: current_business)
    cat.words << FactoryBot.build(
      :trigger_word,
      text: 'not existing'
    )
    cat
  end

  let!(:trigger_category4) do
    cat = FactoryBot.create(:trigger_category, business: current_business)
    cat.words << FactoryBot.build(
      :trigger_word,
      text: 'something went wrong'
    )
    cat
  end

  it 'should returns correct report' do
    report1 = Trigger::TriggerCategoryCalculator.new.call(trigger_category1)
    expect(report1.mentions_count).to eq(2)
    expect(report1.patients_count).to eq(2)

    report2 = Trigger::TriggerCategoryCalculator.new.call(trigger_category2)
    expect(report2.mentions_count).to eq(1)
    expect(report2.patients_count).to eq(1)

    report3 = Trigger::TriggerCategoryCalculator.new.call(trigger_category3)
    expect(report3.mentions_count).to eq(0)
    expect(report3.patients_count).to eq(0)

    report4 = Trigger::TriggerCategoryCalculator.new.call(trigger_category4)
    expect(report4.mentions_count).to eq(1)
    expect(report4.patients_count).to eq(1)
  end
end
