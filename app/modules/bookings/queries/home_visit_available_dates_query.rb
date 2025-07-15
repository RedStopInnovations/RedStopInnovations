module Bookings
  module Queries
    class HomeVisitAvailableDatesQuery
      def initialize(practitioner_id:, start_time:, end_time:, time_zone:)
        @start_time = start_time
        @end_time = end_time
        @time_zone = time_zone
        @practitioner_id = practitioner_id
      end

      def results
        query = "
            SELECT TO_CHAR(start_time AT TIME ZONE 'UTC' AT TIME ZONE :time_zone, 'YYYY-MM-DD') AS date
            FROM availabilities
            WHERE practitioner_id = :practitioner_id
              AND availability_type_id = :availability_type_id
              AND start_time BETWEEN :start_time AND :end_time
              AND appointments_count < max_appointment
            GROUP BY TO_CHAR(start_time AT TIME ZONE 'UTC' AT TIME ZONE :time_zone, 'YYYY-MM-DD')
          "

        query_results = ApplicationRecord.connection.exec_query(
          ApplicationRecord.send(:sanitize_sql_array, [query, {
            start_time: @start_time,
            end_time: @end_time,
            practitioner_id: @practitioner_id,
            availability_type_id: AvailabilityType::TYPE_HOME_VISIT_ID,
            time_zone: @time_zone
          }])
        ).to_a

        query_results.map do |row| row['date'] end
      end
    end
  end
end