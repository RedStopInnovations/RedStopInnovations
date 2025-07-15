describe Frontend::JobApplicationController, type: :controller do
  describe 'GET #new' do
    it 'return 200 OK' do
      get :new, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  # describe 'POST #create' do
  #   it 'return 200 OK' do
  #     get :new, params: {country: 'au'}
  #     expect(response).to be_ok
  #   end
  # end
end