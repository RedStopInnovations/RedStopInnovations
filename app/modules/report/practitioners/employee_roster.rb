module Report
  module Practitioners
    class EmployeeRoster
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

      private

      def parse_options
        options[:start_date] = Time.zone.parse(options[:start_date].to_s) || 30.days.ago
        options[:end_date] = Time.zone.parse(options[:end_date].to_s) || Date.current

        options[:start_date] = options[:start_date].beginning_of_day
        options[:end_date] = options[:end_date].end_of_day
      end

      def calculate
        practitioners_query = Practitioner.where(business_id: business.id).active.includes(:user)

        if @options[:practitioner_id].present?
          practitioners_query = practitioners_query.where('practitioners.id' => @options[:practitioner_id].to_i)
        end

        practitioners_query = practitioners_query.eager_load(:availabilities).where(
          'availabilities.start_time >= ? AND availabilities.end_time <= ?', options[:start_date], options[:end_date]
        )

        practitioners = practitioners_query.order('practitioners.full_name ASC, availabilities.start_time ASC').load

        @result = {
          practitioners: practitioners
        }
      end
    end
  end
end

