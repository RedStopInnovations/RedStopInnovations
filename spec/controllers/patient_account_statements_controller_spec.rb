describe PatientAccountStatementsController, type: :controller, authenticated: true do
  let!(:patient) { FactoryBot.create(:patient, business: current_business) }

  describe 'GET #index' do
    it 'returns 200 OK' do
      get :index, params: { patient_id: patient.id }
      expect(response).to be_ok
    end
  end

  describe 'GET #published' do
    it 'returns 200 OK' do
      get :published, params: { patient_id: patient.id }
      expect(response).to be_ok
    end
  end
end
