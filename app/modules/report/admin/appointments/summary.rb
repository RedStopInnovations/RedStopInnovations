module Report
  module Admin
    module Appointments
      class Summary
        attr_reader :results, :options

        def initialize(options = {})
          @options = options
          calculate
        end

        def as_csv
          CSV.generate(headers: true) do |csv|
            csv << ["Month", "Appointments"]
            @results.each do |row|
              csv << [
                row[:date].strftime('%B %Y'),
                row[:appointments_count]
              ]
            end
          end
        end

        private

        def calculate
          @results = []

          query =
          "
            SELECT COUNT(id) AS appointments_count, TO_CHAR(start_time AT TIME ZONE 'UTC' AT TIME ZONE :timezone, 'YYYY-MM') AS date
            FROM appointments
            WHERE start_time BETWEEN :start_time AND :end_time
              AND cancelled_at IS NULL
              AND deleted_at IS NULL
            GROUP BY TO_CHAR(start_time AT TIME ZONE 'UTC' AT TIME ZONE :timezone, 'YYYY-MM')
          "
          query_results = ActiveRecord::Base.connection.exec_query(
            ActiveRecord::Base.send(:sanitize_sql_array, [query, {
              start_time: 11.months.ago.beginning_of_month,
              end_time: Time.zone.now,
              timezone: Time.zone.name
            }])
          ).to_a

          tmp_date = 11.months.ago.beginning_of_month.to_date

          12.times do
            appointments_count = query_results.find do |row|
              row['date'] == tmp_date.strftime('%Y-%m')
            end.try(:[], 'appointments_count')

            @results << {
              date: tmp_date,
              appointments_count: appointments_count || 0
            }

            tmp_date = tmp_date.next_month
          end
        end
      end
    end
  end
end