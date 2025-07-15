module Report
  module Charts
    class OutcomeMeasure

      attr_reader :outcome_measure, :data

      def initialize(outcome_measure)
        @outcome_measure = outcome_measure
        calculate
      end

      def calculate
        @data = {
          labels: [],
          datasets: []
        }

        results = []

        tests = outcome_measure.tests.order(date_performed: :asc)
        first_date = tests.first.date_performed

        tests.each do |test|
          day_ordinal = (test.date_performed - first_date).to_i
          @data[:labels] << "Day #{day_ordinal} (#{test.date_performed.strftime('%d/%b')})"
          results << test.result_formatted
        end

        @data[:datasets] << {
          fill: false,
          pointRadius: 5,
          data: results
        }
      end
    end
  end
end
