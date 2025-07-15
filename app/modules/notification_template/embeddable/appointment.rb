module NotificationTemplate
  module Embeddable
    class Appointment < Base
      VARIABLES = [
        'Appointment.ID',
        'Appointment.Date',
        'Appointment.StartTime',
        'Appointment.EndTime',
        'Appointment.AppointmentType',
        'Appointment.ViewDetailsURL',
        'Appointment.ViewInCalendarURL',
      ]

      # @param appointment ::Appointment
      def initialize(appointment)
        @appointment = appointment
        super map_attributes
      end

      private

      def map_attributes
        appt_start_time = @appointment.start_time_in_practitioner_timezone
        appt_end_time = @appointment.end_time_in_practitioner_timezone

        view_details_url = Rails.application.routes.url_helpers.appointment_url(@appointment.id)
        view_in_calendar_url = Rails.application.routes.url_helpers.calendar_url(availability_id: @appointment.availability_id)
        {
          'Appointment.ID' => @appointment.id,
          'Appointment.Date' => appt_start_time.strftime("%a, %d %b %Y"),
          'Appointment.StartTime' => appt_start_time.strftime("%l:%M%P"),
          'Appointment.EndTime' => appt_end_time.strftime("%l:%M%P (%Z)"),
          'Appointment.AppointmentType' => @appointment.appointment_type.name,
          'Appointment.ViewDetailsURL' => view_details_url,
          'Appointment.ViewInCalendarURL' => view_in_calendar_url
        }
      end
    end
  end
end
