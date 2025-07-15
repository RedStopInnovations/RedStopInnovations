module Report
  module Transactions
    class OutstandingInvoices
      class Options
        attr_accessor :start_date, :end_date, :contact_ids, :practitioner_ids, :account_statement_number, :page

        def initialize(attrs = {})
          @practitioner_ids = attrs[:practitioner_ids]
          @contact_ids = attrs[:contact_ids]
          @start_date = attrs[:start_date]
          @end_date = attrs[:end_date]
          @account_statement_number = attrs[:account_statement_number]
        end

        def to_params
          {
            start_date: start_date&.strftime("%Y-%m-%d"),
            end_date: end_date&.strftime("%Y-%m-%d"),
            contact_ids: contact_ids,
            practitioner_ids: practitioner_ids,
            account_statement_number: account_statement_number,
          }
        end
      end

      attr_reader :business, :options, :result

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        calculate
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << [
          "Number",
          "Issue date",
          "Appointment date",
          "Availability start",
          "Availability end",
          "Appointment time",
          "Created at",

          "Client",
          "Client ID",
          "Client active status",
          "Items",
          "Invoice to",

          "Practitioner",
          "Practitioner provider number",
          "Practitioner profession",
          "Practitioner state",

          "Days outstanding",
          "Amount",
          "Amount excluding tax",
          "Outstanding",
          "Tax"
        ]

          @result[:invoices].each do |invoice|
            days_outstanding = nil
            pract = invoice.practitioner
            appt = invoice.appointment
            patient = invoice.patient
            if invoice.issue_date < Date.current
              days_outstanding = (Date.current - invoice.issue_date).to_i
            end

            invoice_items_lines = []
            invoice_items_cell = invoice.items.map(&:unit_name).join("\n")

            csv << [
              invoice.invoice_number,
              invoice.issue_date.strftime('%d %b, %Y'),

              appt&.start_time&.strftime('%d %b, %Y').to_s,
              appt&.start_time&.strftime('%l:%M%P').to_s,
              appt&.end_time&.strftime('%l:%M%P').to_s,
              appt&.arrival&.arrival_at&.strftime('%l:%M%P').to_s,

              invoice.created_at,
              patient.full_name,
              patient.id,
              (patient.archived_at? || patient.deleted_at?) ? 'Inactive' : 'Active',
              invoice_items_cell,
              invoice.invoice_to_contact&.business_name,
              pract&.full_name,
              pract&.medicare,
              pract&.profession,
              pract&.state,
              days_outstanding,
              invoice.amount,
              invoice.amount_ex_tax.to_f.round(2).to_s,
              invoice.outstanding,
              invoice.tax_amount.to_f.round(2).to_s
            ]
          end
        end
      end

      private

      def calculate
        @result = {}

        invoices_query = Invoice.
          where(invoices: { business_id: business.id }).
          where('invoices.outstanding > 0').
          where(issue_date: options.start_date..options.end_date).
          order(issue_date: :asc)

        if options.contact_ids.present?
          invoices_query = invoices_query.where(invoice_to_contact_id: options.contact_ids)
        end

        if options.practitioner_ids.present?
          invoices_query = invoices_query.where('invoices.practitioner_id' => options.practitioner_ids)
        end

        if options.account_statement_number.present?
          sanitized_as_number = options.account_statement_number.to_s.strip.upcase
          if sanitized_as_number.start_with?('#')
            sanitized_as_number[0] = ''
          end

          if sanitized_as_number.size > 0
            as = business.account_statements.where(number: sanitized_as_number).first
            if as
              invoices_query = invoices_query.joins(:account_statements).
                where(account_statements: { id: as.id})
            else
              invoices_query = invoices_query.none
            end
          end
        end

        @result[:invoices] = invoices_query.preload(
            :invoice_to_contact,
            :patient,
            :items,
            :practitioner,
            account_statements: [:source],
            appointment: [
              :arrival
            ],
        )
        @result[:invoices_count] = invoices_query.count
        @result[:paginated_invoices] = @result[:invoices].page(options.page)
        @result[:total_amount] = invoices_query.sum(:amount)
        @result[:total_amount_ex_tax] = invoices_query.sum(:amount_ex_tax)
        @result[:total_outstanding] = invoices_query.sum(:outstanding)
      end
    end
  end
end
