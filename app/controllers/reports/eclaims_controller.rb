module Reports
  class EclaimsController < ApplicationController
    include HasABusiness

    def medicare
      ahoy_track_once 'Use Medicare eclaims'

      @options = parse_report_options

      if @options.valid?
        @report = Report::Eclaim::Medicare.new(current_business, @options)
      end
      respond_to do |f|
        f.html
        f.csv do
          send_data @report.as_csv
        end
      end
    end

    def dva
      ahoy_track_once 'Use DVA eclaims'

      @options = parse_report_options

      if @options.valid?
        @report = Report::Eclaim::Dva.new(current_business, @options)
      end
      respond_to do |f|
        f.html
        f.csv do
          send_data @report.as_csv
        end
      end
    end

    def ndis
      ahoy_track_once 'Use NDIS eclaims'

      @options = parse_report_options

      if @options.valid?
        @report = Report::Eclaim::Ndis.new(current_business, @options)
      end
      respond_to do |f|
        f.html
        f.csv do
          send_data @report.as_csv
        end
      end
    end

    def proda
      ahoy_track_once 'Use PRODA eclaims'

      @options = parse_report_options

      if @options.valid?
        @report = Report::Eclaim::Proda.new(current_business, @options)
      end
      respond_to do |f|
        f.html
        f.csv do
          send_data @report.as_csv
        end
      end
    end

    private

    def parse_report_options
      options = Report::Eclaim::Options.new

      if params[:start_date].present?
        options.start_date = params[:start_date].to_s.to_date rescue nil
      end

      if params[:end_date].present?
        options.end_date = params[:end_date].to_s.to_date rescue nil
      end

      if params[:billable_item_ids].present?
        options.billable_item_ids = params[:billable_item_ids].to_a
      end

      if params[:patient_ids].present?
        sanitized_patient_ids = current_business.
          patients.
          where(id: params[:patient_ids].to_a).
          pluck(:id)

        options.patient_ids = sanitized_patient_ids
      end

      options.unpaid_only = params[:unpaid_only].to_s == '1'

      options
    end
  end
end
