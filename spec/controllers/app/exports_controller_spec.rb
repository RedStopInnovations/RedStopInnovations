describe App::DataExport::ExportsController, type: :controller, authenticated: true do

  describe 'export billable items' do
    let!(:billable_items) do
      FactoryBot.create_list(:billable_item, 10, business: current_business)
    end

    it 'returns CSV with status 200 OK' do
      get :billable_items, params: { format: 'csv' }
      expect(response).to be_ok
    end
  end

  describe 'export appointment types' do
    let!(:appointment_types) do
      FactoryBot.create_list(:appointment_type, 10, business: current_business)
    end

    it 'returns CSV with status 200 OK' do
      get :appointment_types, params: { format: 'csv' }
      expect(response).to be_ok
    end
  end

  describe 'patients' do
    let!(:patients) do
      FactoryBot.create_list(:patient, 10, business: current_business)
    end

    it 'returns CSV with status 200 OK' do
      get :patients, params: { format: 'csv' }
      expect(response).to be_ok
    end
  end

  describe 'contacts' do
    let!(:contacts) do
      FactoryBot.create_list(:contact, 10, business: current_business)
    end

    it 'returns CSV with status 200 OK' do
      get :contacts, params: { format: 'csv' }
      expect(response).to be_ok
    end
  end
end
