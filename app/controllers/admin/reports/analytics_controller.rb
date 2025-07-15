module Admin
  module Reports
    class AnalyticsController < BaseController
      def events
        @options = parse_events_summary_options
        @report = Report::Admin::Analytics::EventsSummary.new(@options)
      end

      private

      def parse_events_summary_options
        options_h = {}

        if params[:name].present?
          options_h[:name] = params[:name].to_s.presence
        end

        if params[:tags].present?
          options_h[:tags] = params[:tags].to_s.presence
        end

        if params[:start_date].present?
          options_h[:start_date] = params[:start_date].to_date
          if params[:end_date].present?
            options_h[:end_date] = params[:end_date].to_date
          end
        end

        if params[:page]
          options_h[:page] = params[:page]
        end

        if params[:business_id].present?
          options_h[:business_id] = params[:business_id]
        end

        Report::Admin::Analytics::EventsSummary::Options.new(options_h)
      end
    end
  end
end