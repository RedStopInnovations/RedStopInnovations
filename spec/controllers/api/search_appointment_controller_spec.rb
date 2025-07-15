describe Api::SearchAppointmentController, type: :controller, authenticated: true do
  let! :practitioner1 do
    user = FactoryBot.create :user, :as_practitioner, business: current_business
    user.practitioner
  end

  let! :practitioner2 do
    user = FactoryBot.create :user, :as_practitioner, business: current_business
    user.practitioner
  end

  let!(:avail1) do
    FactoryBot.create(
      :availability,
      :type_home_visit,
      practitioner: practitioner1,
      start_time: '2022-01-01 08:00',
      end_time: '2022-01-01 11:30',
      business: current_business
    )
  end

  let!(:avail2) do
    FactoryBot.create(
      :availability,
      :type_home_visit,
      practitioner: practitioner2,
      start_time: '2022-01-03 08:00',
      end_time: '2022-01-03 11:30',
      business: current_business
    )
  end

  let!(:avail3) do
    FactoryBot.create(
      :availability,
      :type_home_visit,
      practitioner: practitioner2,
      start_time: '2022-01-03 13:00',
      end_time: '2022-01-03 16:30',
      business: current_business
    )
  end

  describe 'GET #index' do
    context 'search date range' do
      it 'should return avails match the date range' do
        get :index, params: {
          availability_type_id: 1, # Home visit
          start_date: '2022-01-01',
          end_date: '2022-01-01',
          format: 'json'
        }

        expect(response).to be_ok
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:pagination][:total_entries]).to eq(1)
      end
    end

    context 'search by practitioner and date' do
      it 'should return avails matchs the practitioner and date' do
        get :index, params: {
          practitioner_id: practitioner2.id,
          availability_type_id: 1,
          start_date: '2022-01-03',
          end_date: '2022-01-03',
          format: 'json'
        }

        expect(response).to be_ok
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:pagination][:total_entries]).to eq(2)
      end
    end

    context 'no avail match' do
      it 'should return empty data' do
        get :index, params: {
          start_date: '2022-01-10',
          end_date: '2022-01-10',
          format: 'json'
        }

        expect(response).to be_ok
        json_response = JSON.parse(response.body, symbolize_names: true)
        expect(json_response[:pagination][:total_entries]).to eq(0)
      end
    end

  end
end