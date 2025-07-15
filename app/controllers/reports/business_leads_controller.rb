module Reports
  class BusinessLeadsController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :read, :reports
    end

    def index
      ahoy_track_once 'View business leads report'

      @business = current_business
      @options = business_leads_report_options
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
      if params[:practitioner_ids].present? && params[:practitioner_ids].is_a?(Array)
        options_h[:practitioner_ids] = params[:practitioner_ids].to_a.flatten
      end

      Report::Admin::Business::BusinessLeads::Options.new(options_h)
    end
  end
end
