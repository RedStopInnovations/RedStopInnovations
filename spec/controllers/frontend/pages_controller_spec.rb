describe Frontend::PagesController, type: :controller do
  describe 'GET #home' do
    it 'return 200 OK' do
      get :home, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #tos' do
    it 'return 200 OK' do
      get :tos, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #about' do
    it 'return 200 OK' do
      get :about, params: {country: 'au'}
      expect(response).to be_ok
    end
  end


  describe 'GET #home_top_practitioners' do
    it 'return 200 OK' do
      get :home_top_practitioners, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_physiotherapy' do
    it 'return 200 OK' do
      get :mobile_physiotherapy, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_physical_therapy' do
    it 'return 200 OK' do
      get :mobile_physical_therapy, params: {country: 'us'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_occupational_therapy' do
    it 'return 200 OK' do
      get :mobile_occupational_therapy, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_podiatry' do
    it 'return 200 OK' do
      get :mobile_podiatry, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_physiotherapy_brisbane' do
    it 'return 200 OK' do
      get :mobile_physiotherapy_brisbane, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #ndis_physiotherapy_brisbane' do
    it 'return 200 OK' do
      get :ndis_physiotherapy_brisbane, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #sunday_physiotherapy' do
    it 'return 200 OK' do
      get :sunday_physiotherapy, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #north_brisbane_mobile_physiotherapy' do
    it 'return 200 OK' do
      get :north_brisbane_mobile_physiotherapy, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #south_brisbane_mobile_physiotherapy' do
    it 'return 200 OK' do
      get :south_brisbane_mobile_physiotherapy, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_physiotherapy_sydney' do
    it 'return 200 OK' do
      get :mobile_physiotherapy_sydney, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_physiotherapy_melbourne' do
    it 'return 200 OK' do
      get :mobile_physiotherapy_melbourne, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_physiotherapy_canberra' do
    it 'return 200 OK' do
      get :mobile_physiotherapy_canberra, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_physiotherapy_tasmania' do
    it 'return 200 OK' do
      get :mobile_physiotherapy_tasmania, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_physiotherapy_adelaide' do
    it 'return 200 OK' do
      get :mobile_physiotherapy_adelaide, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_physiotherapy_perth' do
    it 'return 200 OK' do
      get :mobile_physiotherapy_perth, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_podiatry_sydney' do
    it 'return 200 OK' do
      get :mobile_podiatry_sydney, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_podiatry_melbourne' do
    it 'return 200 OK' do
      get :mobile_podiatry_melbourne, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_podiatry_brisbane' do
    it 'return 200 OK' do
      get :mobile_podiatry_brisbane, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_podiatry_adelaide' do
    it 'return 200 OK' do
      get :mobile_podiatry_adelaide, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_podiatry_perth' do
    it 'return 200 OK' do
      get :mobile_podiatry_perth, params: {country: 'au'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_physical_therapy_new_york' do
    it 'return 200 OK' do
      get :mobile_physical_therapy_new_york, params: {country: 'us'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_podiatry_new_york' do
    it 'return 200 OK' do
      get :mobile_podiatry_new_york, params: {country: 'us'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_physiotherapy_auckland' do
    it 'return 200 OK' do
      get :mobile_physiotherapy_auckland, params: {country: 'nz'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_podiatry_auckland' do
    it 'return 200 OK' do
      get :mobile_podiatry_auckland, params: {country: 'nz'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_physiotherapy_london' do
    it 'return 200 OK' do
      get :mobile_physiotherapy_london, params: {country: 'uk'}
      expect(response).to be_ok
    end
  end

  describe 'GET #mobile_podiatry_london' do
    it 'return 200 OK' do
      get :mobile_podiatry_london, params: {country: 'uk'}
      expect(response).to be_ok
    end
  end
end