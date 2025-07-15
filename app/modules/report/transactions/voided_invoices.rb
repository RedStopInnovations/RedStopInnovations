module Report
  module Transactions
    class VoidedInvoices
      class Options
        attr_accessor :start_date, :end_date, :page

        def initialize(attrs = {})
          @start_date = attrs[:start_date]
          @end_date = attrs[:end_date]
          @page = attrs[:page]
        end

        def to_param
          params = {}

          if start_date.present?
            params[:start_date] = start_date.strftime('%Y-%m-%d')
          end

          if end_date.present?
            params[:end_date] = end_date.strftime('%Y-%m-%d')
          end

          params
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
            "Service date",
            "Client",
            "Client ID",
            "Client active status",
            "Practitioner",
            "Items",
            "Amount",
            "Created at",
            "Voided at",
            "Voided by"
          ]

          query = invoices_query.preload(
            :items,
            :practitioner,
            deleted_version: :author
          )

          query.find_each do |invoice|
            pract = invoice.practitioner
            voided_by = invoice.deleted_version&.author&.full_name
            patient = invoice.patient

            csv << [
              invoice.invoice_number.to_s,
              invoice.issue_date&.strftime('%d %b, %Y').to_s,
              invoice.service_date&.strftime('%d %b, %Y').to_s,
              patient.full_name,
              patient.id,
              (patient.archived_at? || patient.deleted_at?) ? 'Inactive' : 'Active',
              pract&.full_name,
              invoice.items.map(&:unit_name).join("\n"),
              invoice.amount.to_f.round(2).to_s,
              invoice.created_at,
              invoice.deleted_at,
              voided_by
            ]
          end
        end
      end

      private

      def calculate
        @result = {}

        @result[:invoices_count] = invoices_query.count

        @result[:paginated_invoices] =
          invoices_query.
            preload(
              :items,
              :practitioner,
              deleted_version: :author
            ).
            page(options.page)
      end

      def invoices_query
        query = Invoice.unscoped.
                        where(business_id: business.id).
                        includes(:patient).
                        where("invoices.deleted_at IS NOT NULL")

        if options.start_date && options.end_date
          query = query.where(issue_date: options.start_date..options.end_date)
        end

        query.order(issue_date: :asc)
      end
    end
  end
end
