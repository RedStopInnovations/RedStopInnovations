describe Api::ContactsController, type: :controller, authenticated: true do

  describe 'GET #search' do
    before do
      FactoryBot.create(
        :contact,
        business_name: 'Example company One',
        business: current_business
      )

      FactoryBot.create(
        :contact,
        business_name: 'Example company Two',
        business: current_business
      )
    end

    context 'if no keyword provided' do
      it 'returns no data' do
        get :search, params: {format: 'json'}
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:contacts].size).to eq(0)
      end
    end

    context 'with a match keyword' do
      it 'return list of match contacts with OK status' do
        get :search, params: {
          s: 'Example company',
          format: 'json',
        }
        expect(response).to be_ok
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:contacts].size).to be > 0
      end
    end
  end

  describe 'GET #show' do
    let!(:contact1) do
      FactoryBot.create(
        :contact,
        business_name: 'Abc healthcare',
        business: current_business
      )
    end

    it 'should return contact info and OK status' do
      get :show, params: { id: contact1.id, format: 'json' }
      expect(response).to be_ok
      json_response = JSON.parse(response.body, symbolize_names: true)
      expect(json_response[:contact][:id]).to eq(contact1.id)
    end
  end
end
