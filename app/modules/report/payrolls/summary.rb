module Report
  module Payrolls
    class Summary
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
          csv << ["Practitioner", "Profession", "Availability duration (hrs)", "Appointment duration (hrs)", "Driving distance (km)", "Total invoiced", "Total payments"]

          @result[:data].each do |row|
            csv << [
              "#{row['first_name']} #{row['last_name']}",
              row['profession'],
              row['availability_hours'].to_f.round(2),
              (row['total_appointment_duration'].to_f / 60).round(2),
              (row['distance'].to_f/1000).round(2),
              row['invoiced_amount'].to_f.round(2),
              row['paid_amount'].to_f.round(2)
            ]
          end
        end
      end

      private
      def parse_options
        options[:start_date] = options[:start_date].try(:to_date) || Time.current.days_ago(30)
        options[:end_date] = options[:end_date].try(:to_date) || Time.current
      end

      def calculate
        @result = {}
        query = "
          SELECT
            PRAC.id, PRAC.first_name, PRAC.last_name, PRAC.profession,

            (
              SELECT
                SUM(payment_allocations.amount)
              FROM appointments
              INNER JOIN invoices ON invoices.appointment_id = appointments.id
              INNER JOIN payment_allocations
                ON payment_allocations.invoice_id = invoices.id
              WHERE
                appointments.practitioner_id = PRAC.id
                AND appointments.deleted_at IS NULL
                AND appointments.cancelled_at IS NULL
                AND invoices.deleted_at IS NULL
                AND appointments.start_time >= :start_date
                AND appointments.end_time <= :end_date
              GROUP BY PRAC.id
            ) AS paid_amount,

            (
              SELECT
                SUM(invoices.amount)
              FROM appointments
              INNER JOIN invoices ON invoices.appointment_id = appointments.id
              WHERE
                appointments.practitioner_id = PRAC.id
                AND appointments.deleted_at IS NULL
                AND appointments.cancelled_at IS NULL
                AND invoices.deleted_at IS NULL
                AND appointments.start_time >= :start_date
                AND appointments.end_time <= :end_date
              GROUP BY PRAC.id
            ) AS invoiced_amount,

            (
              SELECT
                SUM(appointment_types.duration)
              FROM appointments
              INNER JOIN appointment_types ON appointments.appointment_type_id = appointment_types.id
              WHERE
                appointments.practitioner_id = PRAC.id
                AND appointments.deleted_at IS NULL
                AND appointments.cancelled_at IS NULL
                AND appointments.start_time >= :start_date
                AND appointments.end_time <= :end_date
              GROUP BY PRAC.id
            ) AS total_appointment_duration,

            SUM(EXTRACT (EPOCH FROM (AVAI.end_time - AVAI.start_time))) / 3600 as availability_hours,
            SUM(AVAI.driving_distance) AS distance
          FROM practitioners PRAC
          LEFT JOIN availabilities AVAI
            ON AVAI.practitioner_id = PRAC.id
            AND AVAI.start_time >= :start_date
            AND AVAI.end_time <= :end_date
          WHERE
            PRAC.business_id = :business_id
            AND PRAC.active = true
        "

        query += " AND PRAC.id IN (:practitioner_ids)" if options[:practitioner_ids].present?
        query += " GROUP BY PRAC.id ORDER BY PRAC.full_name ASC"

        @result[:data] = ActiveRecord::Base.connection.exec_query(
          ActiveRecord::Base.send(:sanitize_sql_array, [query, {start_date: options[:start_date].beginning_of_day,
            end_date: options[:end_date].end_of_day, business_id: business.id, practitioner_ids: options[:practitioner_ids]
          }])
        )
      end
    end
  end
end