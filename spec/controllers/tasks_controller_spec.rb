describe TasksController, type: :controller, authenticated: true do
  describe 'GET #index' do
    it 'return 200 OK' do
      get :index
      expect(response).to be_ok
    end
  end
end