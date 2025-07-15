module Report
  module Patients
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

      def as_chart_data
        data = { labels: [] }
        chart_values = []

        (0..11).each do |index|
          month = 11.months.ago + index.month
          data[:labels] << month.strftime('%b')

          month_amount = @result[:data].select {|row| month.strftime("%Y-%m-01") == row['year_month']}.first
          month_amount = month_amount.present? ? month_amount['patients_count'] : 0
          chart_values << month_amount
        end

        data[:datasets] = [
          {
            label: 'Clients',
            backgroundColor: 'rgba(68, 182, 84, 0.35)',
            borderColorColor: 'rgb(68, 182, 84)',
            pointBackgroundColor: 'rgb(68, 182, 84)',
            pointBorderColor: 'rgb(68, 182, 84)',
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
              row['year_month'].to_date.strftime("%B %d %Y"),
              row['patients_count'],
              JSON.parse(row['patients']).map {|r| r[1]}.join(", ")
            ]
          end
        end
      end

      private
      def parse_options
        options[:start_time] = options[:start_date].try(:to_date) || 11.months.ago.beginning_of_month
        options[:end_time] = options[:end_date].try(:to_date) || Date.current
      end

      def calculate
        @result = {}
        query = "
          SELECT
            COUNT(*) AS patients_count,
            to_char(patients.created_at AT TIME ZONE 'UTC' AT TIME ZONE :timezone, 'YYYY-MM-01') AS year_month,
            json_agg(json_build_array(patients.id, patients.full_name)) as patients
          FROM
            patients
          WHERE
            patients.business_id = :business_id
            AND created_at >= :start_time
            AND created_at <= :end_time
            AND deleted_at IS NULL
          GROUP BY year_month
        "
        @result[:data] = ActiveRecord::Base.connection.exec_query(
          ActiveRecord::Base.send(:sanitize_sql_array, [query, {start_time: options[:start_time].beginning_of_day,
            end_time: options[:end_time].end_of_day, business_id: business.id, timezone: Time.zone.name }])
        )
      end
    end
  end
end
