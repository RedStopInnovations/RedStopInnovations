module Report
  module Appointments
    class Incomplete
      class Options
        attr_accessor :practitioner_ids,
                      :appointment_type_ids,
                      :start_date,
                      :end_date,
                      :status,
                      :is_no_status,
                      :page
        def initialize(options = {})
          @start_date = options[:start_date]
          @end_date = options[:end_date]
          @appointment_type_ids = options[:appointment_type_ids]
          @practitioner_ids = options[:practitioner_ids]
          @status = options[:status]
          @is_no_status = options[:is_no_status]
          @page = options[:page]
        end
      end

      attr_reader :business, :result, :options

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
            "Appointment ID",
            "Appointment date",
            "Availability start",
            "Availability end",
            "Client ID",
            "Client",
            "Client active status",
            "Practitioner",
            "Practitioner profession",
            "Status",
            "Appointment type"
          ]

          result[:all_appointments].each do |appt|
            patient = appt.patient
            next if patient.nil?

            csv << [
              appt.id,
              appt.start_time.try(:strftime, '%d %b %Y').to_s,
              appt.start_time.try(:strftime, '%l:%M%P').to_s,
              appt.end_time.try(:strftime, '%l:%M%P').to_s,
              patient.id,
              patient.full_name,
              (patient.archived_at? || patient.deleted_at?) ? 'Inactive' : 'Active',
              appt.practitioner.full_name,
              appt.practitioner.profession,
              appt.status.try(:humanize),
              appt.appointment_type.name
            ]
          end
        end
      end

      private

      def appointments_query
        all_practitioner_ids = business.practitioners.pluck(:id)

        query = Appointment.where(
            cancelled_at: nil,
            start_time: options.start_date.beginning_of_day..options.end_date.end_of_day
          ).
          where('status is ? OR status <> ?', nil, Appointment::STATUS_COMPLETED).
          order(start_time: :asc).
          includes(:practitioner, :availability, :appointment_type, :patient)

        if options.practitioner_ids.present?
          query = query.where(practitioner_id: options.practitioner_ids)
        else
          query = query.where(practitioner_id: all_practitioner_ids)
        end

        if options.appointment_type_ids.present?
          query = query.where(appointment_type_id: options.appointment_type_ids)
        end

        if options.is_no_status
          query = query.where('status is NULL')
        else
          if options.status.present?
            query = query.where(status: options.status)
          end
        end

        query
      end

      def calculate
        @result = {}
        @result[:paginated_appointments] = appointments_query.page(options.page).per(50)
        @result[:all_appointments] = appointments_query.to_a
      end
    end
  end
end
