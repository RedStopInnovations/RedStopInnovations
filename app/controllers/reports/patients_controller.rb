module Reports
  class PatientsController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :read, :reports
    end

    def new_patient
      ahoy_track_once 'View new patients report'

      @report = Report::Patients::NewPatient.make current_business, parse_new_patient_options

      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv, filename: "new_client_report_#{Time.current.strftime('%Y%m%d')}.csv" }
      end
    end

    def patients_without_upcoming_appointments
      ahoy_track_once 'View patients without upcoming appointments report'

      @report = Report::Patients::WithoutUpcomingAppointments.make current_business, params

      respond_to do |f|
        f.html
        f.csv do
          send_data @report.as_csv,
                    filename: 'clients_without_upcoming_appointments.csv'
        end
      end
    end

    def patient_invoices
      ahoy_track_once 'View patients by total invoice report'

      @options = parse_patients_by_total_invoiced_options

      @report = Report::Patients::PatientInvoices.make(
        current_business,
        @options
      )

      respond_to do |f|
        f.html
        f.csv do
          send_data @report.as_csv, filename: "clients_by_total_invoiced_#{Time.current.strftime('%Y%m%d')}.csv"
        end
      end
    end

    def patient_duplicates
      ahoy_track_once 'View duplicate patients report'

      @report = Report::Patients::Duplicates.make(
        current_business
      )
    end

    def account_statements
      ahoy_track_once 'View published patients account statements report'

      @options = parse_account_statements_report_options
      @report = Report::Patients::AccountStatements.make(
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

      patient_ids = params[:patient_ids]
      if patient_ids && patient_ids.present? && patient_ids.is_a?(Array)
        options[:patient_ids] = current_business.patients.where(id: patient_ids).pluck(:id)
      end

      if params[:payment_status].present?
        options[:payment_status] = params[:payment_status]
      end

      if params[:page]
        options[:page] = params[:page].to_i
      end

      Report::Patients::AccountStatements::Options.new(options)
    end

    private

    def parse_new_patient_options
      options = {}

      if params[:year].present?
        options[:year] = Date.strptime(params[:year], '%Y').strftime('%Y') rescue Date.current.strftime('%Y')
      else
        options[:year] = Date.current.strftime('%Y')
      end

      options
    end

    def parse_patients_by_total_invoiced_options
      options = {}

      if params[:start_date].present? && params[:end_date].present?
        options[:start_date] = params[:start_date].to_s.to_date
        options[:end_date] = params[:end_date].to_s.to_date
      else
        options[:start_date] = 30.days.ago
        options[:end_date] = Date.current
      end

      if params[:last_practitioner_id].present?
        options[:last_practitioner_id] = params[:last_practitioner_id].to_s
      end

      if params[:page]
        options[:page] = params[:page].to_i
      end

      options
    end
  end
end
