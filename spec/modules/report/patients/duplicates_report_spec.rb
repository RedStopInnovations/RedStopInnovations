describe Report::Patients::Duplicates do
  let!(:business) { FactoryBot.create(:business) }

  context 'there is no duplicates' do
    let!(:patient1) {
      FactoryBot.create(
        :patient,
        first_name: 'John',
        last_name: 'Doe',
        business: business
      )
    }

    it 'should return no duplicates' do
      report = Report::Patients::Duplicates.make(business)
      expect(report.result[:duplicates].size).to eq(0)
    end
  end

  context 'there are some duplicates' do
    let!(:patient1) {
      FactoryBot.create(
        :patient,
        first_name: 'John',
        last_name: 'Doe',
        business: business
      )
    }

    let!(:patient2) {
      FactoryBot.create(
        :patient,
        first_name: 'John',
        last_name: 'Doe',
        business: business
      )
    }

    let!(:patient3) {
      FactoryBot.create(
        :patient,
        first_name: 'Leon',
        last_name: 'Hart',
        business: business
      )
    }

    let!(:patient4) {
      FactoryBot.create(
        :patient,
        first_name: 'Leon',
        last_name: 'Hart',
        business: business
      )
    }
    it 'should return correct duplicates' do
      report = Report::Patients::Duplicates.make(business)
      expect(report.result[:duplicates].size).to eq(2)
    end
  end
end
