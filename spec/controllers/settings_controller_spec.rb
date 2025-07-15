describe SettingsController, type: :controller, authenticated: true do
  describe 'GET #index' do
    it 'returns 200 OK' do
      get :index
      expect(response).to be_ok
    end
  end
end