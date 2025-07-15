describe Frontend::BookingsController, type: :controller do
  describe 'GET #index' do
    it 'return 200 OK' do
      get :index, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  # describe 'GET #facility' do
  #   it 'return 200 OK' do
  #     get :facility, params: {country: 'au'}
  #     expect(response).to be_ok
  #   end
  # end
end