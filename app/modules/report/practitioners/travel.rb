module Report
  module Practitioners
    class Travel
      class Options
        attr_accessor :practitioner_ids,
                      :appointment_type_ids,
                      :start_date,
                      :end_date,
                      :page

        def initialize(options = {})
          @start_date = options[:start_date]
          @end_date = options[:end_date]
          @appointment_type_ids = options[:appointment_type_ids]
          @practitioner_ids = options[:practitioner_ids]
          @page = options[:page]
        end

        def to_params
          params = {}

          if start_date.present?
            params[:start_date] = start_date.strftime('%Y-%m-%d')
          end

          if end_date.present?
            params[:end_date] = end_date.strftime('%Y-%m-%d')
          end

          if appointment_type_ids.present?
            params[:appointment_type_ids] = appointment_type_ids
          end

          if practitioner_ids.present?
            params[:practitioner_ids] = practitioner_ids
          end

          params
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

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << [
            "Practitioner",
            "Profession",
            "Appointments count",
            "Appointment duration (hrs)",
            "Travel distance (kms)",
            "Travel duration (hrs)",
            "Total appointment and travel duration (hrs)"
          ]

          @results[:practitioners_stats].each do |practitioner_stats|
            pract = practitioner_stats[:practitioner]
            stats = practitioner_stats[:stats]

            total_travel_distance_kms = stats[:total_travel_distance] > 0 ? (stats[:total_travel_distance].to_f / 1000).round(2) : 0
            total_travel_duration_hrs = stats[:total_travel_duration] > 0 ? (stats[:total_travel_duration].to_f / 3600).round(2) : 0
            total_appt_duration_hrs = stats[:total_appointment_duration] > 0 ? (stats[:total_appointment_duration].to_f / 60).round(2) : 0

            csv << [
              pract.full_name,
              pract.profession,
              stats[:appointments_count],
              total_appt_duration_hrs,
              total_travel_distance_kms,
              total_travel_duration_hrs,
              (total_appt_duration_hrs + total_travel_duration_hrs).round(2)
            ]
          end
        end
      end

      def as_legacy_csv
        appointments_query = Appointment.joins(:availability, :practitioner, :appointment_type)
          .joins("INNER JOIN appointment_arrivals ON appointment_arrivals.appointment_id = appointments.id")
          .where(appointments: { practitioner_id: report_practitioners.map(&:id) })
          .where("appointments.cancelled_at IS NULL")
          .where("appointments.start_time >= ?", options.start_date.beginning_of_day)
          .where("appointments.start_time <= ?", options.end_date.end_of_day)
          .where('availabilities.availability_type_id' => AvailabilityType::TYPE_HOME_VISIT_ID)
          .where('availabilities.hide' => false)
          .where('appointment_arrivals.arrival_at IS NOT NULL')

        appointments_query = appointments_query.where(appointment_type_id: options.appointment_type_ids) if options.appointment_type_ids.present?
        appointments_query = appointments_query.order("appointment_arrivals.arrival_at ASC")

        CSV.generate(headers: true) do |csv|
          csv << [
            "Practitioner",
            "Client",
            "Appointment date",
            "Arrival time",
            "From",
            "To",
            "Distance",
            "Duration"
          ]
          appts = appointments_query.includes(:practitioner, :arrival, :patient).to_a
          appts.each do |appt|
            travel_distance_km = (appt.arrival.travel_distance.to_f / 1000).round(2)
            travel_duration_hr = (appt.arrival.travel_duration.to_f / 3600).round(2)
            csv << [
              appt.practitioner.full_name,
              appt.patient.full_name,
              appt.start_time.strftime('%d %b %Y'),
              appt.arrival.arrival_at.strftime('%l:%M%P'),
              appt.arrival.travel_start_address,
              appt.arrival.travel_dest_address,
              travel_distance_km,
              travel_duration_hr
            ]
          end
        end
      end

      private

      def calculate
        @results = {
          summary: {
            total_travel_distance: 0,
            total_travel_duration: 0
          },
          practitioners_stats: []
        }

        query = Appointment
          .select('practitioner_id')
          .select('SUM(appointment_arrivals.travel_distance) AS total_travel_distance')
          .select('SUM(appointment_arrivals.travel_duration) AS total_travel_duration')
          .select('COUNT(appointments.id) AS appointments_count')
          .select('SUM(appointment_types.duration) AS total_appointment_duration')
          .joins(:availability, :practitioner, :appointment_type)
          .joins("INNER JOIN appointment_arrivals ON appointment_arrivals.appointment_id = appointments.id")
          .joins("LEFT JOIN appointment_types ON appointment_types.id = appointments.appointment_type_id")
          .where(appointments: { practitioner_id: report_practitioners.map(&:id) })
          .where("appointments.cancelled_at IS NULL")
          .where("appointments.start_time >= ?", options.start_date.beginning_of_day)
          .where("appointments.start_time <= ?", options.end_date.end_of_day)
          .where('availabilities.availability_type_id' => AvailabilityType::TYPE_HOME_VISIT_ID)
          .where('availabilities.hide' => false)
          .where('appointment_arrivals.arrival_at IS NOT NULL')

        query = query.where(appointment_type_id: options.appointment_type_ids) if options.appointment_type_ids.present?

        sql = query.group('appointments.practitioner_id').to_sql

        practitioners_raw_stats = ActiveRecord::Base.connection.exec_query(query.group('appointments.practitioner_id').to_sql).to_a

        @results[:summary][:total_travel_distance] = practitioners_raw_stats.sum { |row| row['total_travel_distance'] }
        @results[:summary][:total_travel_duration] = practitioners_raw_stats.sum { |row| row['total_travel_duration'] }

        report_practitioners.each do |pract|

          raw_stats = practitioners_raw_stats.find do |stats|
            stats['practitioner_id'] == pract.id
          end

          if raw_stats
            @results[:practitioners_stats] << {
              practitioner: pract,
              stats: {
                total_travel_distance: raw_stats['total_travel_distance'],
                total_travel_duration: raw_stats['total_travel_duration'],
                total_appointment_duration: raw_stats['total_appointment_duration'],
                appointments_count: raw_stats['appointments_count'],
              }
            }
          else
            @results[:practitioners_stats] << {
              practitioner: pract,
              stats: {
                total_travel_distance: 0,
                total_travel_duration: 0,
                total_appointment_duration: 0,
                appointments_count: 0
              }
            }
          end
        end
      end

      def report_practitioners
        if options.practitioner_ids.present?
          query = business.practitioners.where(id: options.practitioner_ids)
        else
          query = business.practitioners.active
        end

        query.order(full_name: :asc).to_a
      end
    end
  end
end
