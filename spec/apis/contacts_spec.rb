describe "Contact APIs", type: :request do
  let!(:api_user) { FactoryBot.create :user }
  let!(:api_key) { generate_api_key(api_user).token }

  describe 'GET /api/v1/contacts' do
    before do
      FactoryBot.create(
        :contact,
        business_name: 'ABC Ltd',
        business: api_user.business
      )
      FactoryBot.create(
        :contact,
        business_name: 'DEF Co.',
        business: api_user.business
      )
      FactoryBot.create(
        :contact,
        business_name: 'GHI Ltd',
        business: api_user.business
      )
    end

    context 'without filter params' do
      before do
        get(
          "/api/v1/contacts",
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

    context 'filter with business name' do
      context 'with some record matched' do
        it "return the matched record" do
          get(
            "/api/v1/contacts",
            params: {
              filter: {
                business_name_cont: 'DEF'
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
          expect(matched_contact[:attributes][:business_name]).to eq('DEF Co.')
        end
      end

      context 'without any record matched' do
        it "return empty list" do
          get(
            "/api/v1/contacts",
            params: {
              filter: {
                business_name_cont: 'zzz'
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

  describe 'GET /api/v1/contacts/<ID>' do
    let(:contact) {
      FactoryBot.create(
        :contact,
        business_name: 'Elodia Carroll',
        business: api_user.business
      )
    }

    before do
      get(
        "/api/v1/contacts/#{contact.id}",
        params: {},
        headers: auth_headers(api_key)
      )
    end

    it "returns 200" do
      expect(response.status).to eq(200)
    end

    it "returns requested resource" do
      expect(json_response[:data][:id]).to eq(contact.id.to_s)
      expect(json_response[:data][:attributes][:business_name]).to eq('Elodia Carroll')
    end
  end

  describe 'POST /api/v1/contacts' do
    context 'with valid attributes' do
      before do
        post(
          "/api/v1/contacts",
          params: {
            data: {
              attributes: {
                business_name: 'Elodia Carroll',
                metadata: {
                  key1: 'val 1',
                  key2: 'val 2'
                }
              }
            }
          },
          headers: auth_headers(api_key)
        )
      end

      it "returns 201" do
        expect(response.status).to eq(201)
      end

      it "returns created resource" do
        expect(json_response[:data][:attributes][:business_name]).to eq('Elodia Carroll')
        expect(json_response[:data][:attributes][:metadata]).to eq(
          key1: 'val 1',
          key2: 'val 2'
        )
      end
    end

    context 'with invalid attributes' do
      it "returns 422" do
        post(
          "/api/v1/contacts",
          params: {data: { attributes: { business_name: '' }}},
          headers: auth_headers(api_key)
        )
        expect(response.status).to eq(422)
      end
    end
  end
end
