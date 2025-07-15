describe Api::AvailabilitiesController, type: :controller, authenticated: true do
  let! :practitioner1 do
    user = FactoryBot.create :user, :as_practitioner, business: current_business
    user.practitioner
  end

  let! :practitioner2 do
    user = FactoryBot.create :user, :as_practitioner, business: current_business
    user.practitioner
  end

  let!(:patient1) { FactoryBot.create(:patient, business: current_business) }
  let!(:patient2) { FactoryBot.create(:patient, business: current_business) }

  let!(:contact1) { FactoryBot.create(:contact, business: current_business) }

  describe 'GET #index' do

    before do
      [practitioner1, practitioner2].each do |pract|
        FactoryBot.create(
          :availability, :type_home_visit,
          practitioner: pract,
          start_time: '2022-01-01 08:00',
          end_time: '2022-01-01 11:30',
          business: current_business
        )

        FactoryBot.create(
          :availability, :type_non_billable,
          practitioner: pract,
          start_time: '2022-01-01 13:00',
          end_time: '2022-01-01 16:30',
          description: 'Lunch break',
          business: current_business
        )

        FactoryBot.create(
          :availability, :type_home_visit,
          practitioner: pract,
          start_time: '2022-01-01 13:00',
          end_time: '2022-01-01 16:30',
          business: current_business
        )

        FactoryBot.create(
          :availability, :type_home_visit,
          practitioner: pract,
          start_time: '2022-01-02 08:00',
          end_time: '2022-01-02 11:30',
          business: current_business
        )

        FactoryBot.create(
          :availability, :type_non_billable,
          practitioner: pract,
          start_time: '2022-01-03 13:00',
          end_time: '2022-01-03 13:15',
          description: 'Team meeting',
          business: current_business
        )

        FactoryBot.create(
          :availability, :type_home_visit,
          practitioner: pract,
          start_time: '2022-01-03 14:00',
          end_time: '2022-01-03 16:30',
          business: current_business
        )

        FactoryBot.create(
          :availability, :type_facility,
          practitioner: pract,
          start_time: '2022-01-04 09:00',
          end_time: '2022-01-04 16:00',
          contact: contact1,
          business: current_business
        )
      end
    end

    it 'returns 200 OK' do
      get :index, params: {
        from_date: '2022-01-01',
        to_date: '2022-01-07',
        format: 'json',
        practitioner_ids: [practitioner1.id, practitioner2.id]
      }
      expect(response).to be_ok
    end
  end

  describe 'GET #search_by_date' do
    it 'returns 200 OK' do
      get :search_by_date, params: {
        date: '2022-01-01',
        practitioner_id: practitioner1.id, format: 'json'
      }
      expect(response).to be_ok
    end
  end

  describe 'GET #show' do
    context 'a home visit availability' do
      let! :avail1 do
        FactoryBot.create(
          :availability, :type_home_visit,
          practitioner: practitioner1,
          start_time: '2022-01-01 08:00',
          end_time: '2022-01-01 16:00',
          business: current_business
        )
      end

      it 'returns 200 OK' do
        get :show, params: {
          id: avail1.id,
          format: 'json'
        }
        expect(response).to be_ok
      end
    end

    context 'a facility availability' do
      let! :avail1 do
        FactoryBot.create(
          :availability, :type_facility,
          practitioner: practitioner1,
          start_time: '2022-01-01 08:00',
          end_time: '2022-01-01 16:00',
          business: current_business,
          contact: contact1
        )
      end

      it 'returns 200 OK' do
        get :show, params: {
          id: avail1.id,
          format: 'json'
        }
        expect(response).to be_ok
      end
    end

    context 'a non-billable availability' do
      let! :avail1 do
        FactoryBot.create(
          :availability, :type_non_billable,
          practitioner: practitioner1,
          start_time: '2022-01-01 10:00',
          end_time: '2022-01-01 10:30',
          business: current_business,
          description: 'Meeting'
        )
      end

      it 'returns 200 OK' do
        get :show, params: {
          id: avail1.id,
          format: 'json'
        }
        expect(response).to be_ok
      end
    end
  end

  describe 'POST #create' do
    context 'a home visit availability' do
      it 'create the availability and return JSON data' do
        expect {
          post :create, params: {
            availability: {
              availability_type_id: 1,
              start_time: '2022-01-01 08:00',
              end_time: '2022-01-01 16:00',
              practitioner_id: practitioner1.id,
              max_appointment: 5,
              service_radius: 10,
              address1: '123 Main Street',
              city: 'A city',
              state: 'A state',
              postcode: '123456',
              country: 'AU',
            },
            format: 'json'
          }
        }.to change { Availability.count }.by(1)

        expect(response).to have_http_status(201)
      end
    end

    context 'a facility availability' do

      it 'create the availability and return JSON data' do
        expect {
          post :create, params: {
            availability: {
              availability_type_id: 4,
              start_time: '2022-01-01 08:00',
              end_time: '2022-01-01 16:00',
              practitioner_id: practitioner1.id,
              max_appointment: 5,
              address1: '123 Main Street',
              city: 'A city',
              state: 'A state',
              postcode: '123456',
              country: 'AU',
              contact_id: contact1.id
            },
            format: 'json'
          }
        }.to change { Availability.count }.by(1)

        expect(response).to have_http_status(201)
      end
    end
  end

  describe 'POST #single_home_visit' do
    let!(:appointment_type1) {
      FactoryBot.create(:appointment_type, :home_visit, business: current_business)
    }

    it 'create the availability and return JSON data' do
      expect {
        post :single_home_visit, params: {
          availability: {
            availability_type_id: 1,
            start_time: '2022-01-01 09:00',
            end_time: '2022-01-01 10:00',
            practitioner_id: practitioner1.id,
            address1: '123 Main Street',
            city: 'A city',
            state: 'A state',
            postcode: '123456',
            country: 'AU',
            patient_id: patient1.id,
            appointment_type_id: appointment_type1.id,
          },
          format: 'json'
        }
      }.to change { Availability.count }.by(1)
      expect(response).to be_ok
    end
  end

  describe 'POST #non_billable' do
    it 'create the availability and return JSON data' do
      expect {
        post :non_billable, params: {
          availability: {
            availability_type_id: 1,
            start_time: '2022-01-01 12:00',
            end_time: '2022-01-01 12:30',
            practitioner_id: practitioner1.id,
            address1: '123 Main Street',
            city: 'A city',
            state: 'A state',
            postcode: '123456',
            country: 'AU',
            name: 'Testing',
            description: 'Testing',
          },
          format: 'json'
        }
      }.to change { Availability.count }.by(1)
      expect(response).to be_ok
    end
  end

  describe 'POST #group_appointment' do

    let!(:appointment_type1) {
      FactoryBot.create(:appointment_type, :group_appointment, business: current_business)
    }

    it 'create the availability and return JSON data' do
      expect {
        post :group_appointment, params: {
          availability: {
            practitioner_id: practitioner1.id,
            start_time: '2022-01-01 12:00',
            end_time: '2022-01-01 12:30',
            address1: '123 Main Street',
            city: 'A city',
            state: 'A state',
            postcode: '123456',
            country: 'AU',
            description: 'A group appointment',
            contact_id: contact1.id,
            appointment_type_id: appointment_type1.id,
            max_appointment: 20
          },
          format: 'json'
        }
      }.to change { Availability.count }.by(1)
      expect(response).to be_ok
    end
  end

  describe 'PUT #update_time' do
    let! :avail1 do
      FactoryBot.create(
        :availability, :type_home_visit,
        practitioner: practitioner1,
        start_time: '2022-01-01 08:00',
        end_time: '2022-01-01 16:00',
        business: current_business
      )
    end

    it 'should update the availability' do
      put :update_time, params: {
        id: avail1.id,
        availability: {
          start_time: '2022-01-01 09:00',
          end_time: '2022-01-01 16:00'
        },
        format: 'json'
      }

      expect(response).to be_ok

      verify_avail1 = Availability.find(avail1.id)
    end
  end

  describe 'PUT #change_practitioner' do
    let! :avail1 do
      start_time = 3.days.from_now
      FactoryBot.create(
        :availability, :type_home_visit,
        practitioner: practitioner1,
        start_time: start_time,
        end_time: start_time + 1.hour,
        business: current_business
      )
    end

    it 'should update the availability' do
      put :change_practitioner, params: {
        id: avail1.id,
        practitioner_id: practitioner2.id,
        format: 'json'
      }

      expect(response).to have_http_status(200)

      verify_avail1 = Availability.find(avail1.id)
      expect(verify_avail1.practitioner.id).to be(practitioner2.id)
    end
  end

  describe 'PUT #update' do
    let! :avail1 do
      FactoryBot.create(
        :availability, :type_home_visit,
        practitioner: practitioner1,
        start_time: '2022-01-01 08:00',
        end_time: '2022-01-01 16:00',
        business: current_business
      )
    end

    it 'should update the availability' do
      put :update, params: {
        id: avail1.id,
        availability: {
          start_time: '2022-01-01 09:00',
          end_time: '2022-01-01 16:00',

          practitioner_id: avail1.practitioner_id,
          max_appointment: avail1.max_appointment,
          service_radius: avail1.service_radius,
          address1: avail1.address1,
          city: avail1.city,
          state: avail1.state,
          postcode: avail1.postcode,
          country: avail1.country,
        },
        format: 'json'
      }

      expect(response).to be_ok

      verify_avail1 = Availability.find(avail1.id)
    end
  end

  describe 'DELETE #destroy' do
    let! :avail1 do
      FactoryBot.create(
        :availability, :type_home_visit,
        practitioner: practitioner1,
        start_time: '2022-01-01 08:00',
        end_time: '2022-01-01 16:00',
        business: current_business
      )
    end

    context 'if no appointment booked' do
      it 'should delete the availability' do
        expect {
          delete :destroy, params: {
            id: avail1.id,
            format: 'json'
          }
        }.to change{ Availability.count }.by(-1)

        expect(response).to have_http_status(204)
      end
    end

    context 'if has more than 1 appointment' do
      before do

        home_visit_appointment_type1 = FactoryBot.create(
          :appointment_type, :home_visit, business: current_business
        )

        FactoryBot.create(
          :appointment,
          practitioner: practitioner1,
          patient: patient1,
          availability: avail1,
          appointment_type: home_visit_appointment_type1,
          start_time: avail1.start_time,
          end_time: avail1.end_time
        )

        FactoryBot.create(
          :appointment,
          practitioner: practitioner1,
          patient: patient2,
          availability: avail1,
          appointment_type: home_visit_appointment_type1,
          start_time: avail1.start_time,
          end_time: avail1.end_time
        )
      end

      it 'should not allow delete the availability' do
        expect {
          delete :destroy, params: {
            id: avail1.id,
            format: 'json'
          }
        }.not_to change{ Availability.count }

        expect(response).to have_http_status(422)
      end
    end
  end

  describe 'PUT #lock_order' do
    let! :avail1 do
      FactoryBot.create(
        :availability, :type_home_visit,
        practitioner: practitioner1,
        start_time: '2022-01-01 08:00',
        end_time: '2022-01-01 16:00',
        business: current_business
      )

      it 'should mark the order of appointments as locked' do
        put :lock_order, params: { id: avail1.id, format: 'json' }
        verify_avail1 = Availability.find(avail1.id)
        expect(verify_avail1.order_locked).to be(true)
      end
    end
  end

  describe 'PUT #unlock_order' do
    let! :avail1 do
      FactoryBot.create(
        :availability, :type_home_visit,
        practitioner: practitioner1,
        start_time: '2022-01-01 08:00',
        end_time: '2022-01-01 16:00',
        business: current_business
      )
    end

    it 'should mark the order of appointments as unlocked' do
      put :unlock_order, params: { id: avail1.id, format: 'json' }
      verify_avail1 = Availability.find(avail1.id)
      expect(verify_avail1.order_locked).to be(false)
    end
  end
end
