module Report
  module Patients
    class PatientInvoices
      attr_reader :business, :result, :options

      def self.make(business, options = {})
        new(business, options)
      end

      def initialize(business, options = {})
        @business = business
        @options = options
        calculate
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << ["Client ID", "Client", "Number of invoices", "Invoices amount", "Last appointment"]

          patients_query.find_in_batches(batch_size: 500) do |patients|
            last_appointments = Appointment.where(id: patients.map(&:last_appointment_id)).
              includes(:appointment_type, practitioner: :user).
              to_a

            patients.each do |patient|
              last_appt = last_appointments.find { |appt| appt.patient_id == patient.id }
              last_appt_info = nil

              if last_appt
                last_appt_info = [
                  "Date: #{last_appt.start_time_in_practitioner_timezone.strftime(I18n.t('date.common'))}",
                  "Practitioner: #{last_appt.practitioner.full_name}",
                  "Type: #{last_appt.appointment_type.name}",
                ].join("\n")
              end

              csv << [
                patient.id,
                patient.full_name,
                patient.invoices_count,
                patient.invoiced_amount,
                last_appt_info
              ]
            end
          end
        end
      end

      private

      def calculate
        @result = {}

        query = patients_query

        @result[:paginated_patients] = query.page(options[:page])
      end

      def patients_query
        query = business.patients.
          joins(:invoices).
          joins('
          LEFT JOIN
            (
              SELECT
                appointments.patient_id, MAX(appointments.id) AS last_appointment_id, appointments.practitioner_id AS last_practitioner_id
              FROM appointments
              INNER JOIN
                (
                SELECT
                  appointments.patient_id AS patient_id,
                  MAX(appointments.start_time) AS max_start_time
                FROM appointments
                WHERE
                  appointments.start_time < NOW() AND
                  appointments.cancelled_at IS NULL AND appointments.deleted_at IS NULL
                GROUP BY appointments.patient_id
                ) last_appointment_times
                ON last_appointment_times.patient_id = appointments.patient_id AND max_start_time = appointments.start_time
              WHERE
                  appointments.cancelled_at IS NULL AND appointments.deleted_at IS NULL
              GROUP BY appointments.patient_id, appointments.practitioner_id
            ) patient_last_appointments
                ON patient_last_appointments.patient_id = patients.id
          ').
          select(:id, :first_name, :last_name, :full_name).
          select('SUM(invoices.amount) AS invoiced_amount, COUNT(invoices.id) AS invoices_count').
          select('patient_last_appointments.last_appointment_id').
          where('invoices.issue_date' => report_date_range)

        if @options[:last_practitioner_id]
          query = query.where('patient_last_appointments.last_practitioner_id' => @options[:last_practitioner_id])
        end

        query.
          order('full_name ASC').
          group('patients.id, patient_last_appointments.last_appointment_id')
      end

      def report_date_range
        @options[:start_date]..@options[:end_date]
      end
    end
  end
end
