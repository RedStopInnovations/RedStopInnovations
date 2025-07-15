module Reports
  class TransactionsController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :read, :reports
    end

    def outstanding_invoices
      ahoy_track_once 'View outstanding invoices report'

      @options = parse_outstanding_invoices_options

      @report = Report::Transactions::OutstandingInvoices.make(
        current_business,
        @options
      )
      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv }
      end
    end

    def invoices_raised
      ahoy_track_once 'View invoices summary report'

      @options = parse_invoice_raised_options

      @report = Report::Transactions::InvoicesRaised.make(
        current_business,
        @options
      )

      respond_to do |f|
        f.html
        f.csv {
          if params[:csv_type] == 'xero'
            send_data @report.as_xero_csv
          else
            send_data @report.as_csv, filename: "invoices_summary_#{Time.current.strftime('%Y%m%d')}.csv"
          end
        }
      end
    end

    def unsent_invoices
      ahoy_track_once 'View unsent invoices report'

      @report = Report::Transactions::UnsentInvoices.make current_business, params

      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv }
      end
    end

    def payment_summary
      ahoy_track_once 'View payments summary report'

      @report = Report::Transactions::PaymentsSummary.make current_business, params

      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv }
      end
    end

    def voided_invoices
      ahoy_track_once 'View voided summary report'

      @report = Report::Transactions::VoidedInvoices.make(
        current_business,
        parse_voided_invoices_options
      )

      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv }
      end
    end

    def product_sales
      ahoy_track_once 'View product sales report'

      @report = Report::Transactions::ProductSales.make(
        current_business,
        parse_product_sales_options
      )

      respond_to do |f|
        f.html
        f.csv {
          send_data @report.as_csv, filename: "product_sales_#{Time.current.strftime('%Y%m%d')}.csv"
        }
      end
    end

    private

    def parse_invoice_raised_options
      options = Report::Transactions::InvoicesRaised::Options.new

      if params[:start_date].present? && params[:end_date].present?
        options.start_date = params[:start_date].to_s.to_date
        options.end_date = params[:end_date].to_s.to_date
      else
        options.start_date = Date.current.beginning_of_month
        options.end_date = Date.current
      end

      if params[:contact_ids].present? && params[:contact_ids].is_a?(Array)
        options.contact_ids = params[:contact_ids]
      end

      if params[:practitioner_ids].present? && params[:practitioner_ids].is_a?(Array)
        options.practitioner_ids = current_business.practitioners.
          where(id: params[:practitioner_ids]).
          pluck(:id)
      elsif params[:practitioner_group_id].present?
        options.practitioner_group_id = current_business.groups.
          find_by(id: params[:practitioner_group_id]).
          try(:id)
      end

      if params[:billable_item_ids].present? && params[:billable_item_ids].is_a?(Array)
        options.billable_item_ids = current_business.billable_items.
          where(id: params[:billable_item_ids]).
          pluck(:id)
      end

      if params[:has_tax].present?
        options.has_tax = 1 if params[:has_tax] == '1'
        options.has_tax = 0 if params[:has_tax] == '0'
      end

      if params[:billing_type].present? && [Appointment.name, Task.name, 'NOT_SPECIFIED'].include?(params[:billing_type])
        options.billing_type = params[:billing_type]
      end

      if params[:page].present?
        options.page = params[:page]
      end

      options
    end

    def parse_outstanding_invoices_options
      options = Report::Transactions::OutstandingInvoices::Options.new

      if params[:start_date].present? && params[:end_date].present?
        options.start_date = params[:start_date].to_s.to_date
        options.end_date = params[:end_date].to_s.to_date
      else
        options.start_date = 1.year.ago.to_date
        options.end_date = Date.current
      end

      if params[:practitioner_ids].present? && params[:practitioner_ids].is_a?(Array)
        options.practitioner_ids = params[:practitioner_ids]
      end

      if params[:contact_ids].present? && params[:contact_ids].is_a?(Array)
        options.contact_ids = params[:contact_ids]
      end

      if params[:account_statement_number].present?
        options.account_statement_number = params[:account_statement_number]
      end

      if params[:page].present?
        options.page = params[:page]
      end

      options
    end

    def parse_voided_invoices_options
      options = Report::Transactions::VoidedInvoices::Options.new

      if params[:start_date].present? && params[:end_date].present?
        begin
          options.start_date = params[:start_date].to_s.to_date
          options.end_date = params[:end_date].to_s.to_date
        rescue ArgumentError
          options.start_date = nil
          options.end_date = nil
        end
      end

      if params[:page].present?
        options.page = params[:page]
      end

      options
    end

    def parse_product_sales_options
      options = Report::Transactions::InvoicesRaised::Options.new

      if params[:start_date].present? && params[:end_date].present?
        options.start_date = params[:start_date].to_s.to_date
        options.end_date = params[:end_date].to_s.to_date
      else
        options.start_date = Date.current.beginning_of_month
        options.end_date = Date.current
      end

      if params[:contact_ids].present? && params[:contact_ids].is_a?(Array)
        options.contact_ids = params[:contact_ids]
      end

      if params[:practitioner_ids].present? && params[:practitioner_ids].is_a?(Array)
        options.practitioner_ids = params[:practitioner_ids]
      end

      if params[:page].present?
        options.page = params[:page]
      end

      options
    end
  end
end
