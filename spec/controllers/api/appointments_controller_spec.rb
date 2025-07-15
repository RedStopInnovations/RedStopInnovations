describe Api::AppointmentsController, type: :controller, authenticated: true do
  let! :practitioner1 do
    user = FactoryBot.create :user, :as_practitioner, business: current_business
    user.practitioner
  end

  let! :practitioner2 do
    user = FactoryBot.create :user, :as_practitioner, business: current_business
    user.practitioner
  end

  let!(:patient1) { FactoryBot.create(:patient, business: current_business) }

  let!(:home_visit_appointment_type1) do
    FactoryBot.create(:appointment_type, :home_visit, business: current_business)
  end

  let!(:home_visit_appointment_type2) do
    FactoryBot.create(:appointment_type, :home_visit, business: current_business)
  end

  let!(:facility_appointment_type1) do
    FactoryBot.create(:appointment_type, :facility, business: current_business)
  end

  describe 'GET #show' do
    let!(:appointment1) do
      avail1 = FactoryBot.create(
        :availability,
        :type_home_visit,
        practitioner: practitioner1,
        start_time: '2022-01-01 08:00',
        end_time: '2022-01-01 11:30',
        business: current_business
      )

      appt = FactoryBot.create(
        :appointment,
        practitioner: practitioner1,
        patient: patient1,
        availability: avail1,
        appointment_type: home_visit_appointment_type1,
        start_time: avail1.start_time,
        end_time: avail1.end_time
      )

      appt
    end

    it 'returns OK status' do
      get :show, params: {
        id: appointment1.id,
        format: 'json'
      }

      expect(response).to be_ok
    end
  end

  describe 'POST #creates' do
    let!(:home_visit_avail1) do
      FactoryBot.create(
        :availability,
        :type_home_visit,
        practitioner: practitioner1,
        start_time: '2022-01-01 08:00',
        end_time: '2022-01-01 11:30',
        business: current_business
      )
    end

    context 'with valid params' do
      it 'create the appointent and returns JSON' do
        expect {
          post :creates,
                params: {
                  patient_id: patient1.id,
                  appointment_type_id: home_visit_appointment_type1.id,
                  availability_ids: [home_visit_avail1.id],
                  format: 'json'
                }
        }.to change { Appointment.count }.by(1)
        expect(response).to be_ok
      end
    end

    context 'with invalid params' do
      it 'should not create the appointent and returns 422 status' do
        expect {
          post :creates,
                params: {
                  patient_id: nil,
                  appointment_type_id: home_visit_appointment_type1.id,
                  availability_ids: [home_visit_avail1.id],
                  format: 'json'
                }
        }.not_to change { Appointment.count }
        expect(response).to have_http_status(422)
      end
    end
  end

  describe 'POST #update' do
    let!(:appointment1) do
      avail1 = FactoryBot.create(
        :availability,
        :type_home_visit,
        practitioner: practitioner1,
        start_time: '2022-01-01 08:00',
        end_time: '2022-01-01 11:30',
        business: current_business
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
    end

    context 'change type and update the notes' do
      it 'should save the changes and return OK status' do
        post :update,
              params: {
                id: appointment1.id,
                appointment: {
                  availability_id: appointment1.availability_id,
                  appointment_type_id: home_visit_appointment_type2.id,
                  notes: 'An updated note'
                },
                format: 'json'
              }
        expect(response).to be_ok
        verify_appt = Appointment.find(appointment1.id)
        expect(verify_appt.notes).to eq('An updated note')
        expect(verify_appt.appointment_type_id).to eq(home_visit_appointment_type2.id)
      end
    end

  end

  describe 'DELETE #destroy' do
    let!(:appointment1) do
      avail1 = FactoryBot.create(
        :availability,
        :type_home_visit,
        practitioner: practitioner1,
        start_time: '2022-01-01 08:00',
        end_time: '2022-01-01 11:30',
        business: current_business
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
    end

    it 'should delete the app and return OK status' do
      delete :destroy, params: { id: appointment1.id, format: 'json' }
      expect(response).to have_http_status(204)
      verify_appt = Appointment.unscoped.find(appointment1.id)
      expect(verify_appt.deleted_at).not_to be_nil
    end
  end

  describe 'PUT #update_status' do
    let!(:appointment1) do
      avail1 = FactoryBot.create(
        :availability,
        :type_home_visit,
        practitioner: practitioner1,
        start_time: '2022-01-01 08:00',
        end_time: '2022-01-01 11:30',
        business: current_business
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
    end

    it 'save the status and return OK status' do
      put :update_status, params: {
        id: appointment1.id,
        appointment: {
          status: 'completed'
        },
        format: 'json'
      }
      verify_appt = Appointment.unscoped.find(appointment1.id)
      expect(verify_appt.status).to eq('completed')
    end
  end

  describe 'PUT #mark_confirmed' do
    let!(:appointment1) do
      avail1 = FactoryBot.create(
        :availability,
        :type_home_visit,
        practitioner: practitioner1,
        start_time: '2022-01-01 08:00',
        end_time: '2022-01-01 11:30',
        business: current_business
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
    end

    it 'save the confirm status and return OK status' do
      put :mark_confirmed, params: {
        id: appointment1.id,
        format: 'json'
      }
      expect(response).to be_ok
      verify_appt = Appointment.unscoped.find(appointment1.id)
      expect(verify_appt.is_confirmed).to eq(true)
    end
  end

  describe 'PUT #mark_unconfirmed' do
    let!(:appointment1) do
      avail1 = FactoryBot.create(
        :availability,
        :type_home_visit,
        practitioner: practitioner1,
        start_time: '2022-01-01 08:00',
        end_time: '2022-01-01 11:30',
        business: current_business
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
    end

    it 'save the confirm status and return OK status' do
      put :mark_unconfirmed, params: {
        id: appointment1.id,
        format: 'json'
      }
      expect(response).to be_ok
      verify_appt = Appointment.unscoped.find(appointment1.id)
      expect(verify_appt.is_confirmed).to eq(false)
    end
  end

  describe 'PUT #cancel' do
    let!(:appointment1) do
      avail1 = FactoryBot.create(
        :availability,
        :type_home_visit,
        practitioner: practitioner1,
        start_time: '2022-01-01 08:00',
        end_time: '2022-01-01 11:30',
        business: current_business
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
    end

    it 'mark the appt cancelled and return OK status' do
      put :cancel, params: {
        id: appointment1.id,
        format: 'json'
      }
      expect(response).to have_http_status(204)
      verify_appt = Appointment.unscoped.find(appointment1.id)
      expect(verify_appt.cancelled_at).not_to be_nil
    end
  end

end