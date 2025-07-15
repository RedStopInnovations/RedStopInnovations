describe DailyAppointmentsReminder::Worker do
  let!(:business1) { FactoryBot.create(:business) }
  let!(:business2) { FactoryBot.create(:business) }
  let!(:patient1) { FactoryBot.create(:patient, business: business1) }
  let!(:patient2) { FactoryBot.create(:patient, business: business2) }
  let!(:appointment_type1) {
    FactoryBot.create(:appointment_type, :home_visit, business: business1)
  }
  let!(:appointment_type2) {
    FactoryBot.create(:appointment_type, :home_visit, business: business2)
  }
  let!(:user1) {
    FactoryBot.create(
      :user,
      :as_practitioner,
      timezone: 'Australia/Brisbane', # +10
      business: business1
    )
  }

  let!(:user2) {
    FactoryBot.create(
      :user,
      :as_practitioner,
      timezone: 'Hanoi', # +7
      business: business2
    )
  }

  context 'No appointments scheduled' do
    it 'does not send notification' do
      expect {
        DailyAppointmentsReminder::Worker.new.perform
      }.not_to change { DailyAppointmentsNotification.count }
    end
  end

  context 'Some appointments scheduled' do
    let!(:current_time) {
      Time.now.in_time_zone('Australia/Brisbane').change(
        hour: 23,
        min: 1,
        sec: 0
      )
    }

    before do
      # Stub Time.current
      allow(Time).to receive(:current).and_return(current_time)
      av1_start_time = (current_time + 1.day).change(
        hour: 8,
        min: 0
      )

      av2_start_time = (current_time + 1.day).change(
        hour: 10,
        min: 0
      )
      av1 = FactoryBot.create(
        :availability,
        :type_home_visit,
        start_time: av1_start_time + 1.hour,
        end_time: av1_start_time + 2.hour,
        practitioner: user1.practitioner
      )

      FactoryBot.create(
        :appointment,
        patient: patient1,
        availability: av1,
        start_time: av1.start_time,
        end_time: av1.end_time,
        practitioner: user1.practitioner,
        appointment_type: appointment_type1
      )

      av2 = FactoryBot.create(
        :availability,
        :type_home_visit,
        start_time: av2_start_time + 1.hour,
        end_time: av2_start_time + 2.hour,
        practitioner: user2.practitioner
      )

      FactoryBot.create(
        :appointment,
        patient: patient1,
        availability: av2,
        start_time: av2.start_time,
        end_time: av2.end_time,
        practitioner: user2.practitioner,
        appointment_type: appointment_type2
      )
    end

    it 'send notification to correct user' do
      expect {
        DailyAppointmentsReminder::Worker.new.perform
      }.to change { DailyAppointmentsNotification.count }.from(0).to(1)
    end

    context 'notification is already sent' do
      before do
        DailyAppointmentsNotification.create!(
          practitioner_id: user1.practitioner.id,
          date: (current_time + 1.day).to_date
        )
      end

      it 'does not send more' do
        expect {
          DailyAppointmentsReminder::Worker.new.perform
        }.not_to change { DailyAppointmentsNotification.count }
      end
    end
  end
end
