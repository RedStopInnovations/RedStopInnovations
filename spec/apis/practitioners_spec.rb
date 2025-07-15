describe "Practitioner APIs", type: :request do
  let!(:api_user) { FactoryBot.create :user }
  let!(:api_key) { generate_api_key(api_user).token }

  describe 'GET /api/v1/practitioners' do
    before do
      FactoryBot.create_list(
        :user,
        2,
        business: api_user.business
      )

      get(
        "/api/v1/practitioners",
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

  describe 'GET /api/v1/practitioners/<ID>' do
    let(:practitioner) {
      FactoryBot.create(
        :user,
        email: 'lorum@example.com',
        business: api_user.business
      )
    }

    before do
      get(
        "/api/v1/practitioners/#{practitioner.id}",
        params: {},
        headers: auth_headers(api_key)
      )
    end

    it "returns 200 OK" do
      expect(response.status).to eq(200)
    end

    it "returns requested resource" do
      expect(json_response[:data][:id]).to eq(practitioner.id.to_s)
      expect(json_response[:data][:attributes][:email]).to eq('lorum@example.com')
    end
  end

  # describe 'POST /api/v1/practitioners' do
  #   context 'with valid attributes' do
  #     before do
  #       post(
  #         "/api/v1/practitioners",
  #         params: {
  #           data: {
  #             attributes: {
  #               email: 'lorum@gmail.com',
  #               first_name: FFaker::Name.first_name,
  #               last_name: FFaker::Name.last_name,
  #               metadata: {
  #                 key1: 'val 1',
  #                 key2: 'val 2'
  #               }
  #             }
  #           }
  #         },
  #         headers: auth_headers(api_key)
  #       )
  #     end

  #     it "returns 201" do
  #       expect(response.status).to eq(201)
  #     end

  #     it "returns created resource" do
  #       expect(json_response[:data][:attributes][:email]).to eq('lorum@gmail.com')
  #         expect(json_response[:data][:attributes][:metadata]).to eq(
  #           key1: 'val 1',
  #           key2: 'val 2'
  #         )
  #     end
  #   end

  #   context 'with invalid attributes' do
  #     it "returns 422" do
  #       post(
  #         "/api/v1/practitioners",
  #         params: {
  #           data: {
  #             attributes: {
  #               email: "lorum@gmail.com",
  #               first_name: '',
  #               last_name: ''
  #             }
  #           }
  #         },
  #         headers: auth_headers(api_key)
  #       )

  #       expect(response.status).to eq(422)
  #     end
  #   end
  # end
end
