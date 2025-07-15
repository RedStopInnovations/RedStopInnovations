module Report
  module Patients
    class NewPatient

      attr_reader :business, :options, :result

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        calculate
      end

      def as_chart_data
        data = { labels: [] }
        chart_values = []

        @result[:data].each do |row|
          data[:labels] << row['year_month'].to_date.strftime("%b %Y")
          chart_values << row['patients_count']
        end

        data[:datasets] = [
          {
            label: 'Clients',
            data: chart_values
          }
        ]

        data
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << ["Month", "Clients count", "Clients"]

          @result[:data].each do |row|
            csv << [
              row['year_month'].to_date.strftime("%B %Y"),
              row['patients_count'],
              JSON.parse(row['patients_full_name']).join(", ")
            ]
          end
        end
      end

      private

      def calculate
        @result = {}

        query = "
          SELECT
            COUNT(*) AS patients_count,
            TO_CHAR(patients.created_at AT TIME ZONE 'UTC' AT TIME ZONE :timezone, 'YYYY-MM-01') AS year_month,
            JSON_AGG(patients.full_name) AS patients_full_name
          FROM
            patients
          WHERE
            patients.business_id = :business_id
            AND created_at >= :start_time
            AND created_at <= :end_time
            AND deleted_at IS NULL
          GROUP BY year_month
        "
        year_to_date = Date.parse("#{options[:year]}-01-01")

        raw_data = ActiveRecord::Base.connection.exec_query(
          ActiveRecord::Base.send(:sanitize_sql_array, [query, {start_time: year_to_date.beginning_of_year,
            end_time: year_to_date.end_of_year, business_id: business.id, timezone: Time.zone.name }])
        )

        raw_data = raw_data.sort_by do |row|
          row['year_month'].to_date.strftime('%m').to_i
        end

        @result[:data] = raw_data
      end
    end
  end
end
