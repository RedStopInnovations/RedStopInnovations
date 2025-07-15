describe Api::PatientsController, type: :controller, authenticated: true do

  describe 'GET #search' do
    before do
      FactoryBot.create(
        :patient,
        first_name: 'Vincent',
        last_name: 'Curtis',
        business: current_business
      )

      FactoryBot.create(
        :patient,
        first_name: 'Ethel',
        last_name: 'Arnold',
        business: current_business
      )
    end

    context 'if no keyword provided' do
      it 'returns no data' do
        get :search, params: {format: 'json'}
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:patients].size).to eq(0)
      end
    end

    context 'with a match keyword' do
      it 'return list of match patients with OK status' do
        get :search, params: {
          s: 'Vincent',
          format: 'json',
        }
        expect(response).to be_ok
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:patients].size).to be > 0
      end
    end
  end

  describe 'GET #show' do
    let!(:patient1) do
      FactoryBot.create(
        :patient,
        first_name: 'John',
        last_name: 'Doe',
        business: current_business
      )
    end

    it 'should return patient info and OK status' do
      get :show, params: { id: patient1.id, format: 'json' }
      expect(response).to be_ok
      json_response = JSON.parse(response.body, symbolize_names: true)
      expect(json_response[:patient][:id]).to eq(patient1.id)
    end
  end

  describe 'POST #create' do
    context 'if params is invalid' do
      it 'should not create patient and return 422 error' do
        post :create, params: {
          patient: {
            last_name: '',
            first_name: '',
            dob: 'invalid date'
          },
          format: 'json'
        }

        expect(response).to have_http_status(422)
      end
    end

    context 'if params is valid' do
     it 'should save the patient and return OK status' do
        post :create, params: {
          patient: {
            first_name: 'John',
            last_name: 'Doe',
            dob: '1970-01-01',
            address1: '100 Main Street',
            city: 'A city',
            state: 'A state',
            postcode: '12345',
            country: 'AU'
          },
          format: 'json'
        }

        expect(response).to be_ok
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:patient][:first_name]).to eq('John')
        expect(json_response[:patient][:last_name]).to eq('Doe')
        expect(json_response[:patient][:dob]).to eq('1970-01-01')
      end
    end
  end

  describe 'instance actions' do
    let!(:patient1) do
      FactoryBot.create(
        :patient,
        first_name: 'John',
        last_name: 'Doe',
        business: current_business
      )
    end

    describe 'GET #patient_cases' do
      it 'return OK status' do
        get :patient_cases, params: { id: patient1.id, format: 'json' }
        expect(response).to be_ok
      end
    end

    describe 'GET #appointments' do
      it 'return OK status' do
        get :appointments, params: { id: patient1.id, format: 'json' }
        expect(response).to be_ok
      end
    end

    describe 'GET #recent_invoices' do
      it 'return OK status' do
        get :recent_invoices, params: { id: patient1.id, format: 'json' }
        expect(response).to be_ok
      end
    end

    describe 'GET #invoice_to_contacts' do
      it 'return OK status' do
        get :invoice_to_contacts, params: { id: patient1.id, format: 'json' }
        expect(response).to be_ok
      end
    end

    describe 'GET #payment_methods' do
      it 'return OK status' do
        get :payment_methods, params: { id: patient1.id, format: 'json' }
        expect(response).to be_ok
      end
    end
  end
end
