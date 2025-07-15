module Reports
  class ContactsController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :read, :reports
    end

    def referral_source
      ahoy_track_once 'View contacts referral source report'

      options = params
      options[:type] = PatientContact::TYPE_REFERRER

      @report = Report::Contacts::PatientContacts.make current_business, options

      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv }
      end
    end

    def total_patients
      ahoy_track_once 'View contacts by total clients report'

      @report = Report::Contacts::TotalPatients.make(
        current_business, parse_total_patients_report_options
      )

      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv }
      end
    end

    def total_invoice
      ahoy_track_once 'View contacts by total invoice report'

      @options = parse_total_invoice_report_options
      @report = Report::Contacts::TotalInvoices.make(
        current_business, @options
      )
      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv }
      end
    end

    def duplicates
      ahoy_track_once 'View duplicate contacts report'

      @report = Report::Contacts::Duplicates.make(
        current_business
      )
    end

    def account_statements
      ahoy_track_once 'View published contacts account statements report'

      @options = parse_account_statements_report_options
      @report = Report::Contacts::AccountStatements.make(
        current_business,
        @options
      )
    end

    private

    def parse_account_statements_report_options
      options = {}

      if params[:search].present?
        options[:search] = params[:search]
      end

      if params[:start_date].present?
        options[:start_date] = params[:start_date].try(:to_date)
      end

      if params[:end_date].present?
        options[:end_date] = params[:end_date].try(:to_date)
      end

      contact_ids = params[:contact_ids]
      if contact_ids && contact_ids.is_a?(Array) && contact_ids.present?
        options[:contact_ids] = current_business.contacts.where(id: contact_ids).pluck(:id)
      end

      if params[:payment_status].present?
        options[:payment_status] = params[:payment_status]
      end

      if params[:page]
        options[:page] = params[:page].to_i
      end

      Report::Contacts::AccountStatements::Options.new(options)
    end

    def parse_total_invoice_report_options
      options = {}

      if params[:start_date].blank? && params[:end_date].blank?
        options[:start_date] = Date.current.beginning_of_month
        options[:end_date] = Date.current
      else
        options[:start_date] = params[:start_date].try(:to_date)
        options[:end_date] = params[:end_date].try(:to_date)
      end

      contact_ids = params[:contact_ids]
      if contact_ids && contact_ids.is_a?(Array) && !contact_ids.blank?
        options[:contact_ids] = contact_ids
      end

      if params[:page]
        options[:page] = params[:page].to_i
      end

      Report::Contacts::TotalInvoices::Options.new(options)
    end

    def parse_total_patients_report_options
      options = {}

      contact_ids = params[:contact_ids]

      if contact_ids && contact_ids.is_a?(Array) && !contact_ids.blank?
        options[:contact_ids] = contact_ids
      end

      if params[:page]
        options[:page] = params[:page].to_i
      end

      Report::Contacts::TotalPatients::Options.new(options)
    end
  end
end
