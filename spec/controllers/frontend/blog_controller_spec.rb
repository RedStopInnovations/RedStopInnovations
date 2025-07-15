describe Frontend::BlogController, type: :controller do
  let!(:practitioner_user_1) { FactoryBot.create(:user, :as_practitioner, business: current_business) }
  let!(:post_1) { FactoryBot.create(:post, :as_published, practitioner: practitioner_user_1.practitioner) }
  let!(:post_2) { FactoryBot.create(:post, :as_published, practitioner: practitioner_user_1.practitioner) }

  describe 'GET #index' do
    it 'return 200 OK' do
      get :index, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #search' do
    it 'return 200 OK' do
      get :index, params: {s: 'physio', country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #post' do
    it 'return 200 OK' do
      get :post, params: {slug: post_1.slug, country: 'au' }
      expect(response).to be_ok
    end
  end
end