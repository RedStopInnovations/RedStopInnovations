describe ContactAccountStatementsController, type: :controller, authenticated: true do
  let!(:contact) { FactoryBot.create(:contact, business: current_business) }

  describe 'GET #index' do
    it 'returns 200 OK' do
      get :index, params: { contact_id: contact.id }
      expect(response).to be_ok
    end
  end

  describe 'GET #published' do
    it 'returns 200 OK' do
      get :published, params: { contact_id: contact.id }
      expect(response).to be_ok
    end
  end
end
