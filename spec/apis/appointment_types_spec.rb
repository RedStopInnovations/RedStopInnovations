describe "Appointment type APIs", type: :request do
  let!(:api_user) { FactoryBot.create :user }
  let!(:api_key) { generate_api_key(api_user).token }

  describe 'GET /api/v1/appointment_types' do
    before do
      FactoryBot.create_list(
        :appointment_type,
        2,
        business: api_user.business
      )

      get(
        "/api/v1/appointment_types",
        params: {
          page: {
            size: 50,
            number: 1
          }
        },
        headers: auth_headers(api_key)
      )
    end

    it "returns 200 OK" do
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

  describe 'GET /api/v1/<ID>' do
    let(:appt_type) {
      FactoryBot.create(
        :appointment_type,
        name: 'Appointment type 1',
        business: api_user.business
      )
    }

    before do
      get(
        "/api/v1/appointment_types/#{appt_type.id}",
        headers: auth_headers(api_key)
      )
    end

    it "returns 200 OK" do
      expect(response.status).to eq(200)
    end

    it "returns requested resource" do
      expect(json_response[:data][:id]).to eq(appt_type.id.to_s)
      expect(json_response[:data][:attributes][:name]).to eq('Appointment type 1')
    end
  end
end
