describe Frontend::TeamController, type: :controller do
  describe 'GET #index' do
    it 'return 200 OK' do
      get :index, params: {country: 'au'}
      expect(response).to be_ok
    end

    context 'with profession search' do
      it 'return 200 OK' do
        get :index, params: {country: 'au', profession: 'Physiotherapist'}
        expect(response).to be_ok
      end
    end

    context 'with location search' do
      it 'return 200 OK' do
        get :index, params: {country: 'au', location: 'Melbourne VIC, Australia'}
        expect(response).to be_ok
      end
    end
  end

  describe 'GET #profile' do
    let!(:practitioner_user_1) { FactoryBot.create(:user, :as_practitioner) }

    it 'return 200 OK' do
      get :profile, params: {country: 'au', slug: practitioner_user_1.practitioner.slug }
      expect(response).to be_ok
    end
  end

  describe 'GET #modal_profile' do
    let!(:practitioner_user_1) { FactoryBot.create(:user, :as_practitioner) }

    it 'return 200 OK' do
      get :modal_profile, params: {country: 'au', slug: practitioner_user_1.practitioner.slug }
      expect(response).to be_ok
    end
  end
end