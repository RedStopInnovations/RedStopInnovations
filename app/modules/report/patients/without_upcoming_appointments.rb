module Report
  module Patients
    class WithoutUpcomingAppointments
      attr_reader :business, :options, :result

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        parse_options
        calculate
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << ["Client", "Phone", "Mobile", "Appointments", "Last appointment"]

          @result[:data].each do |row|
            last_appt = row['last_appointment']

            last_appt_info = [
              "Date: #{last_appt.start_time_in_practitioner_timezone.strftime(I18n.t('date.common'))}",
              "Practitioner: #{last_appt.practitioner.full_name}",
              "Type: #{last_appt.appointment_type.name}",
            ].join("\n")

            csv << [
              row['full_name'],
              row['phone'].to_s,
              row['mobile'].to_s,
              row['appointments_count'],
              last_appt_info,
            ]
          end
        end
      end

      private

      def parse_options
        options[:start_date] = options[:start_date].try(:to_date) || 30.days.ago
        options[:end_date] = options[:end_date].try(:to_date) || Date.current
      end

      def calculate
        # TODO: rewrite query to get the last appointment info
        @result = {}
        query = "
          SELECT
            patients.id, patients.first_name, patients.last_name, patients.full_name,
            patients.email, patients.phone, patients.mobile,
            COALESCE((
              SELECT
                COUNT(appointments.id)
              FROM appointments
              WHERE
                appointments.patient_id = patients.id
                AND appointments.deleted_at IS NULL
                AND appointments.cancelled_at IS NULL
                AND appointments.start_time >= :start_time
                AND appointments.start_time <= :end_time
              GROUP BY appointments.patient_id
            ), 0) AS appointments_count,
            (
              SELECT
                appointments.id
              FROM appointments
              WHERE
                appointments.patient_id = patients.id
                AND appointments.deleted_at IS NULL
                AND appointments.cancelled_at IS NULL
                AND appointments.start_time >= :start_time
                AND appointments.start_time <= :end_time
              ORDER BY appointments.start_time DESC
              LIMIT 1
            ) AS last_appointment_id,

            (
              SELECT
                appointments.practitioner_id
              FROM appointments
              WHERE
                appointments.patient_id = patients.id
                AND appointments.deleted_at IS NULL
                AND appointments.cancelled_at IS NULL
                AND appointments.start_time >= :start_time
                AND appointments.start_time <= :end_time
              ORDER BY appointments.start_time DESC
              LIMIT 1
            ) AS last_practitioner_id

          FROM patients
          INNER JOIN appointments PAPT
            ON PAPT.patient_id = patients.id
            AND PAPT.deleted_at IS NULL
            AND PAPT.cancelled_at IS NULL
            AND PAPT.start_time >= :start_time
            AND PAPT.end_time <= :end_time
          LEFT JOIN appointments FAPT
            ON FAPT.patient_id = patients.id
            AND FAPT.deleted_at IS NULL
            AND FAPT.cancelled_at IS NULL
            AND FAPT.start_time >= :end_time
          WHERE
            patients.deleted_at IS NULL AND
            patients.archived_at IS NULL
            AND patients.business_id = :business_id
          GROUP BY patients.id
          HAVING COUNT(FAPT.id) = 0
          ORDER BY patients.last_name ASC
        "
        rows = ActiveRecord::Base.connection.exec_query(
          ActiveRecord::Base.send(:sanitize_sql_array, [query, {start_time: options[:start_date].beginning_of_day,
          end_time: options[:end_date].end_of_day, business_id: business.id
          }])
        )

        if options[:practitioner_id].present?
          rows = rows.filter do |row|
            row['last_practitioner_id'].to_s == options[:practitioner_id].to_s
          end
        end

        # Fetch and map the last appointment and patient to each row
        last_appointment_ids = rows.pluck 'last_appointment_id'
        last_appointments = Appointment.where(id: last_appointment_ids).includes(:patient, :appointment_type, practitioner: :user)

        rows.each do |row|
          row['last_appointment'] = last_appointments.find { |appt| appt.id == row['last_appointment_id'] }
        end

        if options[:appointment_type_ids].is_a?(Array) && options[:appointment_type_ids].present?
          rows = rows.filter do |row|
            row['last_appointment'].present? && options[:appointment_type_ids].include?(row['last_appointment'].appointment_type_id.to_s)
          end
        end

        @result[:data] = rows
      end
    end
  end
end
