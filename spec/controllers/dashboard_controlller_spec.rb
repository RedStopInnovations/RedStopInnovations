describe DashboardController, type: :controller, authenticated: true do
  describe 'GET #index' do
    context 'business logged' do
      it 'returns 200 OK' do
        get :index
        expect(response).to be_ok
      end
    end
  end
end