module Admin
  module Reports
    class BusinessController < BaseController
      def business_leads
        @options = business_leads_report_options
        @report = Report::Admin::Business::AllBusinessLeads.new(@options)
      end

      def business_leads_details
        @business = Business.find(params[:business_id])
        @options = single_business_leads_report_options
        @report = Report::Admin::Business::BusinessLeads.new(@business, @options)
      end

      private

      def business_leads_report_options
        options_h = {}
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

        Report::Admin::Business::AllBusinessLeads::Options.new(options_h)
      end

      def single_business_leads_report_options
        options_h = {}
        if params[:start_date].present?
          options_h[:start_date] = params[:start_date].to_date
          if params[:end_date].present?
            options_h[:end_date] = params[:end_date].to_date
          end
        end

        if params[:page]
          options_h[:page] = params[:page]
        end
        if params[:practitioner_ids].present? && params[:practitioner_ids].is_a?(Array)
          options_h[:practitioner_ids] = params[:practitioner_ids].to_a.flatten
        end

        Report::Admin::Business::BusinessLeads::Options.new(options_h)
      end
    end
  end
end
