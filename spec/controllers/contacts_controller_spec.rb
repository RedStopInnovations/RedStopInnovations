describe ContactsController, type: :controller, authenticated: true do
  let!(:contact1) { FactoryBot.create(:contact, business: current_business) }

  describe 'GET #index' do
    it 'return 200 OK' do
      get :index
      expect(response).to be_ok
    end
  end

  describe 'GET #new' do
    it 'return 200 OK' do
      get :new
      expect(response).to be_ok
    end
  end

  describe 'GET #show' do
    it 'return 200 OK' do
      get :show, params: { id: contact1.id }
      expect(response).to be_ok
    end
  end


  describe 'GET #edit' do
    it 'return 200 OK' do
      get :edit, params: { id: contact1.id }
      expect(response).to be_ok
    end
  end

  describe 'POST #create' do
    context 'Params valid' do
      it 'return redirect to #index' do
        expect {
          post :create, params: { contact: { business_name: "Celesta Bins" } }
        }.to change { Contact.count }.by(1)
        expect(response).to have_http_status(302)
      end
    end

    context 'Params invalid' do
      it 'return render template #new' do
        post :create, params: { contact: { business_name: "" } }
        expect(response).to render_template(:new)
      end
    end
  end
end
