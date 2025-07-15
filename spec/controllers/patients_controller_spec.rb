describe PatientsController, type: :controller, authenticated: true do
  let!(:patient1) { FactoryBot.create(:patient, business: current_business) }

  describe 'GET #index' do
    it 'return 200 OK' do
      get :index
      expect(response).to be_ok
    end
  end

  describe 'GET #new' do
    it 'returns 200 OK' do
      get :new
      expect(response).to be_ok
    end
  end

  describe 'GET #show' do
    it 'returns 200 OK' do
      get :show, params: { id: patient1.id }
      expect(response).to be_ok
    end
  end

  describe 'GET #edit' do
    it 'returns 200 OK' do
      get :edit, params: { id: patient1.id }
      expect(response).to be_ok
    end
  end

  describe 'POST #create' do
    context 'with invalid info' do
      it 'wont create patient' do
        post :create, params: {
          patient: {
            first_name: '',
            last_name: '',
            dob: ''
          }
        }
        expect(response).to render_template(:new)
      end
    end

    context 'with valid info' do
      it 'store patient and redirect to created patient page' do
        expect {
          post :create, params: {
            patient: {
              first_name: 'John',
              last_name: 'Doe',
              dob: '1975-01-01',
              address1: '123 Main Street',
              city: 'Test city',
              state: 'Test state',
              postcode: '12345',
              country: 'AU'
            }
          }
        }.to change { Patient.count }.by(1)
        expect(response).to have_http_status(302)
      end
    end
  end

  describe 'PUT #update' do
    context 'with invalid info' do
      it 'wont update the patient' do
        put :update, params: {
          id: patient1.id,
          patient: {
            first_name: '',
            last_name: '',
            dob: ''
          }
        }
        expect(response).to render_template(:edit)
      end
    end

    context 'with valid info' do
      it 'update the patient' do
        put :update, params: {
          id: patient1.id,
          patient: {
            first_name: 'Corrected first name',
            last_name: 'Corrected last name',
            mobile: '1234567890',
            dob: '1975-01-01',
            address1: '123 Main Street',
            city: 'Test city',
            state: 'Test state',
            postcode: '12345',
            country: 'AU'
          }
        }
        verify_patient1 = Patient.find(patient1.id)
        expect(verify_patient1.first_name).to eq('Corrected first name')
        expect(verify_patient1.last_name).to eq('Corrected last name')
        expect(verify_patient1.mobile).to eq('1234567890')
      end
    end
  end

  describe 'GET #invoices' do
    it 'returns 200 OK' do
      get :invoices, params: { id: patient1.id }
      expect(response).to be_ok
    end
  end

  describe 'GET #appointments' do
    it 'returns 200 OK' do
      get :appointments, params: { id: patient1.id }
      expect(response).to be_ok
    end
  end

  describe 'GET #payments' do
    it 'returns 200 OK' do
      get :payments, params: { id: patient1.id }
      expect(response).to be_ok
    end
  end

  describe 'GET #payments' do
    it 'returns 200 OK' do
      get :payments, params: { id: patient1.id }
      expect(response).to be_ok
    end
  end

  describe 'GET #outstanding_invoices' do
    it 'returns 200 OK' do
      get :outstanding_invoices, params: { id: patient1.id, format: 'json' }
      expect(response).to be_ok
    end
  end

  describe 'GET #credit_card_info' do
    it 'returns 200 OK' do
      get :credit_card_info, params: { id: patient1.id, format: 'json' }
      expect(response).to be_ok
    end
  end
end