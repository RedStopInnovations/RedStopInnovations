describe "Patient attachment APIs", type: :request do
  let!(:api_user) { FactoryBot.create :user }
  let!(:api_key) { generate_api_key(api_user).token }
  let!(:patient1) {
    FactoryBot.create(
      :patient,
      first_name: 'John',
      last_name: 'Doe',
      business: api_user.business
    )
  }

  describe 'GET /api/v1/patients/:id/attachments' do
    before do
      get(
        "/api/v1/patients/#{patient1.id}/attachments",
        headers: auth_headers(api_key)
      )
    end

    it "returns 200" do
      expect(response.status).to eq(200)
    end
  end

  describe 'POST /api/v1/patients/:id/attachments' do
    context 'with valid data' do
      before do
        post(
          "/api/v1/patients/#{patient1.id}/attachments",
          params: {
            data: {
              attributes: {
                description: 'Sample attachment description',
                attachment: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/images/sample-avatar.png'), "image/png")
              }
            }
          },
          headers: auth_headers(api_key)
        )
      end

      it "returns 201" do
        expect(response.status).to eq(201)
      end

      it "created attachment" do
        expect(patient1.attachments.count).to eq(1)
        expect(json_response[:data][:attributes][:description]).to eq('Sample attachment description')
      end
    end
  end
end