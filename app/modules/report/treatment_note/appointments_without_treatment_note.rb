module Report
  module TreatmentNote
    class AppointmentsWithoutTreatmentNote
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

          if start_date
            params[:start_date] = start_date.strftime('%Y-%m-%d')
          end

          if start_date
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
            "Time", "Client ID", "Client", "Practitioner", "Status", "Appointment type"
          ]
          result[:all_appointments].each do |appt|
            csv << [
              appt.start_time.strftime('%d %b %Y - %l:%M%P (%Z)'),
              appt.patient_id,
              appt.patient.full_name,
              appt.practitioner.full_name,
              appt.status.try(:humanize),
              appt.appointment_type.name
            ]
          end
        end
      end

      private

      def appointments_query
        query = business.appointments.where(
            cancelled_at: nil,
            start_time: options.start_date.beginning_of_day..options.end_date.end_of_day
          ).
          joins("LEFT JOIN treatments ON treatments.appointment_id = appointments.id").
          where("treatments.id IS NULL").
          where(
            'appointments.status IS NULL OR appointments.status <> ?',
            Appointment::STATUS_COMPLETED
          ).
          order(start_time: :asc).
          includes(:patient, :practitioner, :appointment_type).
          group('appointments.id')


        if options.practitioner_ids.present?
          query = query.where(practitioner_id: options.practitioner_ids)
        end

        if options.appointment_type_ids.present?
          query = query.where(appointment_type_id: options.appointment_type_ids)
        end

        query
      end

      def calculate
        @result = {}
        @result[:paginated_appointments] = appointments_query.page(options.page)
        @result[:all_appointments] = appointments_query.to_a
      end
    end
  end
end
