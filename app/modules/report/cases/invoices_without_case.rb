module Report
  module Cases
    class InvoicesWithoutCase
      attr_reader :business, :result, :options

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        parse_options
      end

      def invoices
        invoices_query.order(issue_date: :desc).page(options[:page])
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << ["Number", "Client", "Client Id", "Amount", "Outstanding", "Issue date"]

          invoices_query.find_each do |invoice|
            csv << [
              invoice.invoice_number,
              invoice.patient.full_name,
              invoice.patient.id,
              invoice.amount.round(2).to_s,
              invoice.outstanding.round(2).to_s,
              invoice.issue_date.try(:strftime, '%b %d, %Y')
            ]
          end
        end
      end

      private

      def parse_options
        options[:start_date] = options[:start_date].try(:to_date) || Date.current.beginning_of_month
        options[:end_date] = options[:end_date].try(:to_date) || Date.current
      end

      def invoices_query
        query = business.invoices
                        .where(patient_case_id: nil)
                        .where("issue_date >= ?", options[:start_date])
                        .where("issue_date <= ?", options[:end_date])

        if options[:practitioner_ids].present?
          query = query.joins(:appointment).
            where(appointments: { practitioner_id: options[:practitioner_ids]})
        end

        query
      end
    end
  end
end
