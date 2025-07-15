module Report
  module Appointments
    class Uninvoiced
      class Options
        attr_accessor :practitioner_ids,
                      :appointment_type_ids,
                      :patient_ids,
                      :is_complete,
                      :start_date,
                      :end_date,
                      :page

        def to_params
          {
            start_date: start_date.strftime("%Y-%m-%d"),
            end_date: end_date.strftime("%Y-%m-%d"),
            appointment_type_ids: appointment_type_ids,
            practitioner_ids: practitioner_ids,
            patient_ids: patient_ids,
            is_complete: is_complete ? '1' : nil
          }
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
            "Appointment ID",
            "Appointment Date",
            "Availability Start",
            "Availability End",
            "Practitioner",
            "Practitioner profession",
            "Client",
            "Client ID",
            "Client active status",
            "Status",
            "Appointment type"
          ]

          appointments = appointments_query
            .preload(:availability, :patient, :appointment_type, :practitioner, :arrival)
            .order(start_time: :asc)

          appointments.each do |appt|
            patient = appt.patient
            next if patient.nil?
            csv << [
              appt.id,
              appt.start_time.try(:strftime, '%d %b %Y').to_s,
              appt.availability&.start_time.try(:strftime, '%l:%M%P').to_s,
              appt.availability&.end_time.try(:strftime, '%l:%M%P').to_s,
              appt.practitioner.try(:full_name),
              appt.practitioner.try(:profession),
              patient.full_name,
              patient.id,
              (patient.archived_at? || patient.deleted_at?) ? 'Inactive' : 'Active',
              appt.status.try(:humanize),
              appt.appointment_type.try(:name)
            ]
          end
        end
      end

      private

      def calculate
        @results = {}

        @results[:paginated_appointments] = appointments_query
          .preload(:availability, :patient, :practitioner, appointment_type: :billable_items)
          .order(start_time: :asc)
          .page(options.page)
          .per(50)
      end

      def appointments_query
        query = Appointment.unscoped
                .joins("
                  LEFT JOIN invoices ON invoices.appointment_id = appointments.id
                  AND invoices.deleted_at IS NULL
                ")
                .joins(:patient, :appointment_type, :practitioner)
                .where("patients.deleted_at IS NULL")
                .where("invoices.id IS NULL")
                .where('appointments.is_invoice_required' => true)
                .where("appointments.cancelled_at IS NULL")
                .where("appointments.deleted_at IS NULL")
                .where("appointments.start_time >= ?", options.start_date.beginning_of_day)
                .where("appointments.start_time <= ?", options.end_date.end_of_day)
                .where("practitioners.business_id = ?", business.id )

        query = query.where(practitioner_id: options.practitioner_ids) if options.practitioner_ids.present?
        query = query.where(patient_id: options.patient_ids) if options.patient_ids.present?
        query = query.where(appointment_type_id: options.appointment_type_ids) if options.appointment_type_ids.present?

        if options.is_complete
          query = query.where('appointments.status' => Appointment::STATUS_COMPLETED)
        end

        query
      end
    end
  end
end
