describe "Referral APIs", type: :request do
  let!(:api_user) { FactoryBot.create :user }
  let!(:api_key) { generate_api_key(api_user).token }

  describe 'GET /api/v1/referrals' do
    before do
      referral1 = FactoryBot.create(
        :referral,
        referrer_business_name: 'Company A',
        referrer_name: 'John Doe',
        business_id: api_user.business_id
      )

      referral1.businesses << api_user.business

      referral2 = FactoryBot.create(
        :referral,
        referrer_business_name: 'Company B',
        referrer_name: 'John Doe',
        business_id: api_user.business_id
      )

      referral2.businesses << api_user.business
    end

    context 'without filter params' do
      before do
        get(
          "/api/v1/referrals",
          params: {
            page: {
              size: 50,
              number: 1
            }
          },
          headers: auth_headers(api_key)
        )
      end

      it "returns 200" do
        expect(response.status).to eq(200)
      end

      it "returns list of entires" do
        expect(json_response[:data].size).to eq(2)
      end

      it "returns paginated list of entires" do
        expect(json_response).to has_meta_pagination
        expect(json_response).to has_pagination_links
      end
    end
  end

  describe 'GET /api/v1/referrals/<ID>' do
    let(:referral1) {
      ref = FactoryBot.create(
        :referral,
        referrer_business_name: 'Company A',
        referrer_name: 'John Doe',
        business_id: api_user.business_id
      )

      ref.businesses << api_user.business

      ref
    }

    before do
      get(
        "/api/v1/referrals/#{referral1.id}",
        headers: auth_headers(api_key)
      )
    end

    it "returns 200" do
      expect(response.status).to eq(200)
    end

    it "returns requested resource" do
      expect(json_response[:data][:id]).to eq(referral1.id.to_s)
      expect(json_response[:data][:attributes][:referrer_business_name]).to eq('Company A')
      expect(json_response[:data][:attributes][:referrer_name]).to eq('John Doe')
    end
  end

  describe 'POST /api/v1/referrals' do
    context 'if params is invalid' do

      before do
        post(
          "/api/v1/referrals",
          params: {
            referral_type: 'general',
            professions: ['Not valid profession'],
            referrer_business_name: 'Company A',
            referrer_name: 'John Doe',
            patient_info: {
              first_name: '',
              last_name: '',
              dob: ''
            }
          },
          headers: auth_headers(api_key)
        )
      end

      it "returns 422" do
        expect(response.status).to eq(422)
      end
    end

    context 'if params is valid' do
      let!(:create_params) do
        {
          availability_type: 'HOME_VISIT',
          referral_type: 'general',
          professions: ['Physiotherapist'],
          priority: 'Urgent',

          referrer_business_name: 'Company A',
          referrer_name: 'John Doe',
          referrer_email: 'john.doe@example.com',
          referrer_phone: '12345678',

          referral_reason: 'Testing',
          medical_note: 'Testing',

          patient: {
            first_name: 'John',
            last_name: 'Doe',
            dob: '1970-01-01'
          }
        }
      end

      before do
        post(
          "/api/v1/referrals",
          params: create_params,
          headers: auth_headers(api_key)
        )
      end

      it "returns OK status" do
        expect(response).to have_http_status(201)
      end

      it "returns created referral JSON" do
        expect(json_response.dig(:data, :attributes, :referral_type)).to eq(create_params[:referral_type])
        expect(json_response.dig(:data, :attributes, :referrer_business_name)).to eq(create_params[:referrer_business_name])
        expect(json_response.dig(:data, :attributes, :referrer_name)).to eq(create_params[:referrer_name])

        expect(json_response.dig(:data, :attributes, :patient, :first_name)).to eq(create_params[:patient][:first_name])
        expect(json_response.dig(:data, :attributes, :patient, :last_name)).to eq(create_params[:patient][:last_name])
        expect(json_response.dig(:data, :attributes, :patient, :dob)).to eq(create_params[:patient][:dob])
      end
    end
  end
end
