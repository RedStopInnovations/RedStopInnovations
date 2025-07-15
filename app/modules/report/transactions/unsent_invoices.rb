module Report
  module Transactions
    class UnsentInvoices
      attr_reader :business, :options, :result, :invoices

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        parse_options
        calculate
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << [
            "Number",
            "Client",
            "Client ID",
            "Client active status",
            "Issue date",
            "Amount",
            "Amount excluding tax",
            "Outstanding"
          ]

          result[:invoices].each do |invoice|
            patient = invoice.patient

            csv << [
              invoice.invoice_number,
              patient.full_name,
              patient.id,
              (patient.archived_at? || patient.deleted_at?) ? 'Inactive' : 'Active',
              invoice.issue_date.try(:strftime, '%d %b, %Y'),
              invoice.amount.to_f.round(2).to_s,
              invoice.amount_ex_tax.to_f.round(2).to_s,
              invoice.outstanding.to_f.round(2).to_s
            ]
          end
        end
      end

      private

      def parse_options
        options[:start_date] = options[:start_date].try(:to_date) || 30.days.ago.to_date
        options[:end_date] = options[:end_date].try(:to_date) || Date.current
      end

      def invoices_query
        query = business.invoices.joins(:patient)
                        .where("invoices.deleted_at IS NULL")
                        .where("invoices.issue_date >= ? AND invoices.issue_date <= ?",
                          options[:start_date], options[:end_date])
                        .where("last_send_at IS NULL")
                        .where("patients.deleted_at IS NULL")

        if options[:contact_ids] && options[:contact_ids].is_a?(Array)
          query = query.where(invoice_to_contact_id: options[:contact_ids])
        end

        query.preload(:patient).order(issue_date: :desc)
      end

      def calculate
        @result = {}
        @result[:invoices] = invoices_query.load
        @result[:paginated_invoices] = invoices_query.page(options[:page])
      end
    end
  end
end
