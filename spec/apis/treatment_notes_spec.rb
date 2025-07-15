describe "Treatment note APIs", type: :request do
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
  let!(:patient2) {
    FactoryBot.create(
      :patient,
      :with_medicare_details,
      first_name: 'Peter',
      last_name: 'Pan',
      business: api_user.business
    )
  }
  let!(:treatment_template1) {
    FactoryBot.create :treatment_template, business: api_user.business
  }
  let!(:treatment_template2) {
    FactoryBot.create :treatment_template, business: api_user.business
  }

  describe 'GET /api/v1/treatment_notes' do
    let!(:treatment_note1) {
      FactoryBot.create(
        :treatment,
        patient: patient1,
        author: api_user,
        name: 'Initial treatment',
        treatment_template: treatment_template1
      )
    }

    let!(:treatment_note2) {
      FactoryBot.create(
        :treatment,
        patient: patient2,
        author: api_user,
        name: 'Subsequent treatment',
        treatment_template: treatment_template2
      )
    }

    context 'without filter params' do
      before do
        get(
          "/api/v1/treatment_notes",
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

    context 'filter by patient' do
      context 'has id matches' do
        before do
          get(
            "/api/v1/treatment_notes",
            params: {
              filter: {
                patient_id_eq: patient1.id
              },
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

        it "returns the patient's treatment notes" do
          expect(json_response[:data].size).to eq(1)
          expect(json_response[:data].first[:id]).to eq(treatment_note1.id.to_s)
        end
      end

      # context 'has Medicare details' do
      #   before do
      #     get(
      #       "/api/v1/treatment_notes",
      #       params: {
      #         filter: {
      #           patient_medicare_details_not_null: '1'
      #         },
      #         page: {
      #           size: 50,
      #           number: 1
      #         }
      #       },
      #       headers: auth_headers(api_key)
      #     )
      #   end

      #   it "returns 200" do
      #     expect(response.status).to eq(200)
      #   end

      #   it "returns the patient's treatment notes" do
      #     expect(json_response[:data].size).to eq(1)
      #     expect(json_response[:data].first[:id]).to eq(treatment_note2.id.to_s)
      #   end
      # end
    end
  end
end
