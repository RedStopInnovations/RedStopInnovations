module Admin
  module Reports
    class SubscriptionsController < BaseController
      def revenue_summary
        authorize! :read, :global_revenue_summary_report
        if params[:revenue_type].present? && params[:time_period].present?
          begin
            revenue_type = params[:revenue_type]
            time_period = params[:time_period]
            @report = Report::Admin::RevenueSummary.make(
              revenue_type, time_period
            )
          rescue ArgumentError
            redirect_to admin_reports_revenue_summary_url
          end
        end
      end

      def lifetime_value_summary
        authorize! :read, :global_lifetime_value_summary_report
        if params[:lifetime_value_for].present?
          begin
            lifetime_value_for = params[:lifetime_value_for]
            @report = Report::Admin::LifetimeValueSummary.make(
              lifetime_value_for, params[:page]
            )
          rescue ArgumentError
            redirect_to admin_reports_lifetime_value_summary_url
          end
        end
      end
    end
  end
end
