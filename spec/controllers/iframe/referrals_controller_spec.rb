describe Iframe::ReferralsController, type: :controller do
  describe 'landing' do
    context 'with existing business' do
      let!(:target_business) { FactoryBot.create :business }

      context 'by default template' do
        it 'should render referral form successfully' do
          get :new, params: { business: target_business.id }
          expect(response).to be_ok
        end
      end

      context 'by a specified payment type template' do
        it 'should render referral form successfully' do
          get :new, params: { business: target_business.id, template: 'dva' }
        end
      end

      context 'by self-referral template' do
        it 'should render referral form successfully' do
          get :new, params: { business: target_business.id, template: 'self_referral' }
        end
      end

      context 'by dynamic payment method template' do
        it 'should render referral form successfully' do
          get :new, params: { business: target_business.id, template: 'dpr' }
        end
      end
    end

    context 'with invalid business' do
      it 'should return not found' do
        get :new, params: { business: 111111 }
        expect(response.status).to eq(404)
      end
    end
  end

  describe 'create' do
    let!(:target_business) { FactoryBot.create :business }

    context 'with valid params' do
      it 'should create the referral' do
        expect {
          post :create, params: {
            business: target_business.id,
            referral: {
              availability_type_id: 1, # HomeVisitID
              professions: ['Physiotherapist'],
              patient: {
                first_name: 'John',
                last_name: 'Doe',
                dob: '1980-01-01',
                phone: FFaker::PhoneNumberAU.phone_number,
                email: 'test@example.com',
                address1: FFaker::Address.street_address,
                city: FFaker::AddressAU.city,
                state: FFaker::AddressAU.state_abbr,
                postcode: FFaker::AddressAU.postcode,
                country: 'AU',
                gender: 'Male',
                aboriginal_status: 'No'
              },
              referrer_business_name: FFaker::Name,
              referrer_name: FFaker::Name,
              referrer_phone: FFaker::PhoneNumberAU.phone_number,
              referrer_email: FFaker::Internet.safe_email,
            },
            format: :json
          }
        }.to change{ Referral.count }.by(1)
        expect(response.status).to eq(201)
      end
    end

    context 'with invalid params' do
      it 'should not create referral and return 422' do
        expect {
          post :create, params: {
            business: target_business.id,
            referral: {
              availability_type_id: 'not exist',
              profession: 'invalid'
            },
            format: :json
          }
        }.not_to change{ Referral.count }
        expect(response.status).to eq(422)
      end
    end
  end
end
