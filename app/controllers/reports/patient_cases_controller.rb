module Reports
  class PatientCasesController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :read, :reports
    end

    def all
      ahoy_track_once 'View all patient cases report'

      @options = parse_all_cases_report_options
      @report = Report::Cases::All.make current_business, @options

      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv, filename: "cases_report_#{Time.current.strftime('%Y%m%d')}.csv" }
      end
    end

    def invoice_without_case
      ahoy_track_once 'View invoices without case report'

      @report = Report::Cases::InvoicesWithoutCase.make current_business, params

      respond_to do |f|
        f.html
        f.json do
          render json: {
            data: @report.as_chart_data
          }
        end
        f.csv { send_data @report.as_csv }
      end
    end

    def invoice_total_per_case
      ahoy_track_once 'View invoice total per case report'

      @report = Report::Cases::InvoiceTotalPerCase.make(current_business, params)
      respond_to do |f|
        f.html
        f.json do
          render json: {
            data: @report.as_chart_data
          }
        end
        f.csv { send_data @report.as_csv }
      end
    end

    private

    def parse_all_cases_report_options
      options = Report::Cases::All::Options.new

      if params[:start_date].present? && params[:end_date].present?
        options.start_date = params[:start_date].to_s.to_date
        options.end_date = params[:end_date].to_s.to_date
      else
        options.start_date = 3.months.ago.beginning_of_month
        options.end_date = Date.current
      end

      if !params.key?(:status)
        options.status = PatientCase::STATUS_OPEN
      else
        options.status = params[:status]
      end

      if params[:page].present?
        options.page = params[:page]
      end

      if params[:practitioner_ids].present? && params[:practitioner_ids].is_a?(Array)
        options.practitioner_ids = params[:practitioner_ids]
      end

      if params[:case_type_ids].present? && params[:case_type_ids].is_a?(Array)
        options.case_type_ids = params[:case_type_ids]
      end

      options
    end
  end
end
