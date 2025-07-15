describe Api::BusinessesController, type: :controller, authenticated: true do
  describe 'GET #show' do
    it 'returns 200 OK' do
      get :show, params: { id: current_business.id, format: 'json' }
      expect(response).to be_ok
    end
  end

  describe 'GET #info' do
    it 'returns 200 OK' do
      get :info, params: { format: 'json' }
      expect(response).to be_ok
    end
  end
end
