module Report
  module Practitioners
    class SinglePractitionerTravel
      class Options
        attr_accessor :practitioner_id,
                      :appointment_type_ids,
                      :start_date,
                      :end_date

        def initialize(options = {})
          @start_date = options[:start_date]
          @end_date = options[:end_date]
          @appointment_type_ids = options[:appointment_type_ids]
          @practitioner_id = options[:practitioner_id]
        end
      end

      attr_reader :business, :options, :results

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        calculate
      end

      private

      # Return daily travels
      def calculate
        daily_appointments = {}

        appointments_query.find_each do |appt|
          date = appt.start_time.to_date

          daily_data = {}

          unless daily_appointments[date].present?
            daily_appointments[date] = {
              total_travel_distance: 0.0,
              total_travel_duration: 0.0,
              appointments: []
            }
          end

          daily_appointments[date][:appointments] << appt
          daily_appointments[date][:total_travel_distance] += appt.arrival.travel_distance
          daily_appointments[date][:total_travel_duration] += appt.arrival.travel_duration
        end

        daily_appointments

        @results = {
          daily_appointments: daily_appointments.sort_by do |date, _|
            date.to_time.to_i
          end.to_h
        }
      end

      def appointments_query
        query = Appointment.joins(:availability, :appointment_type, :patient, :arrival)
          .joins("INNER JOIN appointment_arrivals ON appointment_arrivals.appointment_id = appointments.id")
          .where(appointments: { practitioner_id: options.practitioner_id })
          .where("appointments.cancelled_at IS NULL")
          .where("appointments.start_time >= ?", options.start_date.beginning_of_day)
          .where("appointments.start_time <= ?", options.end_date.end_of_day)
          .where('availabilities.availability_type_id' => AvailabilityType::TYPE_HOME_VISIT_ID)
          .where('availabilities.hide' => false)
          .where('appointment_arrivals.arrival_at IS NOT NULL')

        query = query.where(appointment_type_id: options.appointment_type_ids) if options.appointment_type_ids.present?
        query
      end
    end
  end
end
