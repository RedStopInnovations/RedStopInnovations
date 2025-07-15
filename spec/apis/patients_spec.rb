describe "Patient APIs", type: :request do
  let!(:api_user) { FactoryBot.create :user }
  let!(:api_key) { generate_api_key(api_user).token }
  let! :patient1 do
    FactoryBot.create(
      :patient,
      first_name: 'John',
      last_name: 'Doe',
      business: api_user.business
    )
  end

  let! :patient2 do
    FactoryBot.create(
      :patient,
      first_name: 'Peter',
      last_name: 'Pan',
      business: api_user.business
    )
  end

  let! :patient3 do
    FactoryBot.create(
      :patient,
      first_name: 'Alan',
      last_name: 'Smith',
      business: api_user.business,
      medicare_card_number: 'Abc123456',
      medicare_card_irn: '1',
      medicare_referrer_name: 'John Doe',
      medicare_referrer_provider_number: 'Xyz123456',
      medicare_referral_date: '2003-11-10'
    )
  end

  describe 'GET /api/v1/patients' do

    context 'without filter params' do
      before do
        get(
          "/api/v1/patients",
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
        expect(json_response[:data].size).to eq(3)
      end

      it "returns paginated list of entires" do
        expect(json_response).to has_meta_pagination
        expect(json_response).to has_pagination_links
      end
    end

    context 'filter with name' do
      context 'with some record matched' do
        it "return the matched record" do
          get(
            "/api/v1/patients",
            params: {
              filter: {
                full_name_cont: 'John doe'
              },
              page: {
                size: 50,
                number: 1
              }
            },
            headers: auth_headers(api_key)
          )
          expect(response.status).to eq(200)
          expect(json_response[:data]).to be_a Array
          expect(json_response[:data].length).to eq(1)

          matched_contact = json_response[:data].first
          expect(matched_contact[:attributes][:full_name]).to eq('John Doe')
        end
      end

      context 'without any record matched' do
        it "return empty list" do
          get(
            "/api/v1/patients",
            params: {
              filter: {
                full_name_cont: 'zzz'
              },
              page: {
                size: 50,
                number: 1
              }
            },
            headers: auth_headers(api_key)
          )
          expect(response.status).to eq(200)
          expect(json_response[:data].length).to eq(0)
        end
      end
    end
  end

  describe 'GET /api/v1/patients/{id}' do
    context 'patient is existing' do
      before do
        get(
          "/api/v1/patients/#{patient1.id}",
          headers: auth_headers(api_key)
        )
      end

      it "returns 200" do
        expect(response.status).to eq(200)
      end

      it "returns info of patient" do
        expect(json_response[:data][:id].to_s).to eq(patient1.id.to_s)
        expect(json_response[:data][:attributes][:first_name]).to eq('John')
        expect(json_response[:data][:attributes][:last_name]).to eq('Doe')
      end
    end

    context 'patient is not existing' do
      before do
        get(
          "/api/v1/patients/notexisingid",
          headers: auth_headers(api_key)
        )
      end

      it "returns 404" do
        expect(response.status).to eq(404)
      end
    end
  end

  describe 'GET /api/v1/patients/{id}/appointments' do
    before do
      get(
        "/api/v1/patients/#{patient1.id}/appointments",
        headers: auth_headers(api_key)
      )
    end

    it "returns 200" do
      expect(response.status).to eq(200)
    end
  end

  describe 'GET /api/v1/patients/{id}/contact_associations' do
    before do
      get(
        "/api/v1/patients/#{patient1.id}/contact_associations",
        headers: auth_headers(api_key)
      )
    end

    it "returns 200" do
      expect(response.status).to eq(200)
    end
  end

end
