describe Settings::UsersController, type: :controller, authenticated: true do
  describe 'GET #index' do
    before do
      FactoryBot.create_list(
        :user,
        2,
        business: current_business
      )

      FactoryBot.create_list(
        :user,
        2,
        :as_practitioner,
        business: current_business
      )
    end

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
    context 'non-practitioner user' do
      let!(:target_user) do
        FactoryBot.create :user, :as_non_practitioner, business: current_business
      end

      it 'return 200 OK' do
        get :new, params: { id: target_user.id }
        expect(response).to be_ok
      end
    end

    context 'practitioner user' do
      let!(:target_user) do
        FactoryBot.create :user, :as_practitioner, business: current_business
      end

      it 'return 200 OK' do
        get :new, params: { id: target_user.id }
        expect(response).to be_ok
      end
    end
  end

  describe 'POST #create' do
    context 'non-practitioner user' do
      context 'with invalid parameters' do
        it 'should not created user and return 422' do
          expect {
            post :create, params: {
              user: {
                first_name: 'John',
                last_name: '',
                is_practitioner: false,
                role: 'administrator',
              }
            }
          }.to_not change { User.count }
          expect(response).to render_template(:new)
          expect(response).to have_http_status(422)
        end
      end

      context 'with valid parameters' do
        context 'send invitation email' do
          it 'should create user' do
            expect {
              post :create, params: {
                user: {
                  first_name: 'John',
                  last_name: 'Doe',
                  is_practitioner: false,
                  role: 'administrator',
                  email: "email-#{Time.current.to_i}@example.com",
                  timezone: 'Australia/Brisbane',
                  send_invitation_email: true
                }
              }
            }.to change { User.count }.by(1)

            expect(response).to have_http_status(302)
          end
        end

        context 'set a password' do
          it 'should create user' do
            password = '123Qwerty@3!'
            email = "email-#{Time.current.to_i}@example.com"
            expect {
              post :create, params: {
                user: {
                  first_name: 'John',
                  last_name: 'Doe',
                  is_practitioner: false,
                  role: 'administrator',
                  email: email,
                  timezone: 'Australia/Brisbane',
                  password: password,
                  send_invitation_email: false
                }
              }
            }.to change { User.count }.by(1)
            expect(User.find_by(email: email).valid_password?(password)).to be(true)
            expect(response).to have_http_status(302)
          end
        end
      end
    end

    context 'practitioner user' do
      context 'with invalid parameters' do
        it 'should not created user and return 422' do
          post :create, params: {
            user: {
              first_name: 'John',
              last_name: 'Doe',
              is_practitioner: true,
              role: 'practitioner',
              address1: '',
              profession: 'NotExistingProf'
            }
          }
          expect(response).to render_template(:new)
          expect(response).to have_http_status(422)
        end
      end

      context 'with valid parameters' do
        it 'should create user' do
          expect {
            post :create, params: {
              user: {
                first_name: 'John',
                last_name: 'Doe',
                is_practitioner: true,
                role: 'administrator',
                email: "email-#{Time.current.to_i}@example.com",
                timezone: 'Australia/Brisbane',
                address1: FFaker::Address.street_address,
                city: FFaker::AddressAU.city,
                state: FFaker::AddressAU.state_abbr,
                postcode: FFaker::AddressAU.postcode,
                country: 'AU',
                profession: 'Physiotherapist'
              }
            }
          }.to change { User.count }.by(1)
           .and change { Practitioner.count }.by(1)

          expect(response).to have_http_status(302)
        end
      end
    end
  end

  describe 'GET #edit' do
    context 'non-practitioner user' do
      let!(:target_user) do
        FactoryBot.create :user, :as_non_practitioner, business: current_business
      end

      it 'return 200 OK' do
        get :edit, params: { id: target_user.id }
        expect(response).to be_ok
      end
    end

    context 'practitioner user' do
      let!(:target_user) do
        FactoryBot.create :user, :as_practitioner, business: current_business
      end

      it 'return 200 OK' do
        get :edit, params: { id: target_user.id }
        expect(response).to be_ok
      end
    end
  end

  describe 'PUT #update' do
    context 'non-practitioner user' do
      let!(:target_user) do
        FactoryBot.create :user, :as_non_practitioner, business: current_business
      end

      context 'with invalid parameters' do
        it 'should not update user and return 422' do
          put :update, params: {
            id: target_user.id,
            user: {
              first_name: '',
              last_name: '',
              is_practitioner: false,
              role: 'administrator',
            }
          }
          expect(response).to render_template(:edit)
          expect(response).to have_http_status(422)
        end
      end

      context 'with valid parameters' do
          it 'should update user' do
            put :update, params: {
              id: target_user.id,
              user: {
                first_name: 'John',
                last_name: 'Doe',
                is_practitioner: false,
                role: 'administrator',
                email: "email-#{Time.current.to_i}@example.com",
                timezone: 'Australia/Brisbane'
              }
            }

            expect(response).to have_http_status(302)
          end
      end
    end

    context 'practitioner user' do
      let!(:target_user) do
        FactoryBot.create :user, :as_practitioner, business: current_business
      end

      context 'with invalid parameters' do
        it 'should not update user and return 422' do
          put :update, params: {
            id: target_user.id,
            user: {
              first_name: '',
              last_name: '',
              is_practitioner: true,
              role: 'practitioner',
              address1: '',
              profession: 'NotExistingProf'
            }
          }
          expect(response).to render_template(:edit)
          expect(response).to have_http_status(422)
        end
      end

      context 'with valid parameters' do
        it 'should update user' do
          put :update, params: {
            id: target_user.id,
            user: {
              first_name: 'John',
              last_name: 'Doe',
              is_practitioner: true,
              role: 'administrator',
              email: "email-#{Time.current.to_i}@example.com",
              timezone: 'Australia/Brisbane',
              address1: FFaker::Address.street_address,
              city: FFaker::AddressAU.city,
              state: FFaker::AddressAU.state_abbr,
              postcode: FFaker::AddressAU.postcode,
              country: 'AU',
              profession: 'Physiotherapist'
            }
          }

          expect(response).to have_http_status(302)
        end
      end
    end
  end
end
