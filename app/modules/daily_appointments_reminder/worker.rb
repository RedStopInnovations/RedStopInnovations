module DailyAppointmentsReminder
  class Worker < ApplicationJob
    def perform
      now = Time.current
      today = now.to_date
      Practitioner.includes(:user).find_each do |pract|
        localized_tz =
          if pract.user_timezone.present?
            pract.user_timezone
          else
            'UTC'
          end
        now_in_pract_tz = now.in_time_zone(localized_tz)
        today_in_pract_tz = now_in_pract_tz.to_date

        # Check if now is 23h in pract's tz
        if now_in_pract_tz.hour == 23
          tomorrow_in_pract_tz = today_in_pract_tz + 1.day
          log = DailyAppointmentsNotification.find_or_initialize_by(
            practitioner_id: pract.id,
            date: tomorrow_in_pract_tz
          )

          if log.new_record?
            tomorrow_range = (now_in_pract_tz + 1.day).beginning_of_day..(now_in_pract_tz + 1.day).end_of_day
            appts = pract.appointments.
              not_cancelled.
              left_joins(:arrival).
              order('appointment_arrivals.arrival_at ASC').
              includes(:availability).
              where(
                start_time: tomorrow_range
              ).
              to_a
            if appts.size > 0
              log.sent_at = Time.current
              log.save!(validate: false)

              AppointmentReminderMailer.daily_appointments_schedule(
                pract,
                appts
              ).deliver_later
            end
          end
        end
      end
    end
  end
end
