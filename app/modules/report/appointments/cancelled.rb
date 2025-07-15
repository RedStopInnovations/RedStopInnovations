module Report
  module Appointments
    class Cancelled
      attr_reader :business, :options

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        parse_options
      end

      def appointments
        appointments_query.
          preload(:patient, :appointment_type, :practitioner, :cancelled_by_user).
          order(start_time: :desc).page(options[:page]).per(50)
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << [
            "Appointment ID",
            "Appointment date",
            "Availability start",
            "Availability end",
            "Appointment time",
            "Practitioner",
            "Practitioner profession",
            "Client ID",
            "Client",
            "Client active status",
            "Appointment type",
            "Cancelled on",
            "Cancelled by"
          ]

          appointments = appointments_query.
            preload(:patient, :cancelled_by_user, :appointment_type, :practitioner, :arrival).
            order(start_time: :desc)

          appointments.each do |appt|
            patient = appt.patient
            next if patient.nil?

            csv << [
              appt.id,
              appt.start_time.try(:strftime, '%d %b %Y').to_s,
              appt.start_time.try(:strftime, '%l:%M%P').to_s,
              appt.end_time.try(:strftime, '%l:%M%P').to_s,
              appt.arrival&.arrival_at.try(:strftime, '%l:%M%P').to_s,
              appt.practitioner.try(:full_name),
              appt.practitioner.try(:profession),
              patient.id,
              patient.try(:full_name),
              (patient.archived_at? || patient.deleted_at?) ? 'Inactive' : 'Active',
              appt.appointment_type.try(:name),
              appt.cancelled_at.strftime('%d %b %Y %l:%M%P'),
              appt.cancelled_by_user.try(:full_name),
            ]
          end
        end
      end

      private

      def parse_options
        options[:start_date] = options[:start_date].try(:to_date) || 30.days.ago
        options[:end_date] = options[:end_date].try(:to_date) || Date.current
      end

      def appointments_query
        query = Appointment.unscoped.joins(:practitioner, :patient, :appointment_type)
                .where("patients.deleted_at IS NULL")
                .where("appointments.cancelled_at IS NOT NULL")
                .where("appointments.start_time >= ?", options[:start_date].beginning_of_day)
                .where("appointments.start_time <= ?", options[:end_date].end_of_day)
                .where(practitioners: { business_id: business.id })

        query = query.where(practitioner_id: options[:practitioner_ids]) if options[:practitioner_ids].present?
        query = query.where(patient_id: options[:patient_ids]) if options[:patient_ids].present?
        query = query.where(appointment_type_id: options[:appointment_type_ids]) if options[:appointment_type_ids].present?

        if options[:cancel_period].present?
          cancel_max_date =
            case options[:cancel_period]
            when '12h'
              12.hours.ago
            when '24h'
              24.hours.ago
            when '48h'
              48.hours.ago
            when '72h'
              72.hours.ago
            end

          query = query.where('cancelled_at >= ?', cancel_max_date) if cancel_max_date
        end

        query
      end
    end
  end
end
