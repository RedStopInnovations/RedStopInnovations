module Report
  module Transactions
    class ProductSales
      class Options
        attr_accessor :start_date, :end_date, :contact_ids, :practitioner_ids, :page

        def initialize(attrs = {})
          @contact_ids = attrs[:contact_ids]
          @start_date = attrs[:start_date]
          @end_date = attrs[:end_date]
          @practitioner_ids = attrs[:practitioner_ids]
        end

        def to_params
          {
            start_date: start_date.strftime("%Y-%m-%d"),
            end_date: end_date.strftime("%Y-%m-%d"),
            contact_ids: contact_ids,
            practitioner_ids: practitioner_ids
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

      def products_query
        query = Product.joins(invoice_items: :invoice)
          .select(
            "products.*,
            SUM(invoice_items.quantity) AS items_count,
            SUM(invoice_items.amount) AS total_amount"
          )
          .where('invoices.issue_date' => options.start_date..options.end_date)
          .where('invoices.business_id' => business.id)
          .group("products.id")
          .order("products.name ASC")

        if options.contact_ids && options.contact_ids.is_a?(Array)
          query = query.where('invoices.invoice_to_contact_id' => options.contact_ids)
        end

        if options.practitioner_ids.present?
          query = query.where('invoices.practitioner_id' => options.practitioner_ids)
        end

        query.load
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << [
            "Number",
            "Issue date",
            "Created at",
            "Appointment date",

            "Client ID",
            "Client",
            "Client email",
            "Client phone",
            "Client mobile",

            "Items",
            "Items code",
            "Amount",
            "Amount excluding tax",
            "Outstanding",
            "Tax",

            "Practitioner",
            "Practitioner profession",
          ]

          invoices_query.preload(
            :patient,
            :items,
            :appointment,
            :practitioner
          ).find_in_batches(batch_size: 200) do |invoices|
            invoices.each do |invoice|
              appointment = invoice.appointment
              patient = invoice.patient
              pract = invoice.practitioner
              invoice_items_lines = []
              invoice_items_code_lines = []

              invoice.items.each do |item|
                invoice_items_lines << item.unit_name
                invoice_items_code_lines << item.item_number
              end

              invoice_items_cell = invoice_items_lines.join("\n")
              invoice_items_code_cell = invoice_items_code_lines.join("\n")

              csv << [
                invoice.invoice_number.to_s,
                invoice.issue_date.strftime('%d %b, %Y').to_s,
                invoice.created_at,
                appointment&.start_time&.strftime('%d %b, %Y').to_s,

                patient.id,
                patient.full_name,
                patient.email,
                patient.phone,
                patient.mobile,

                invoice_items_cell,
                invoice_items_code_cell,
                invoice.amount.to_f.round(2).to_s,
                invoice.amount_ex_tax.to_f.round(2).to_s,
                invoice.outstanding.to_f.round(2).to_s,
                invoice.tax_amount.to_f.round(2).to_s,

                pract&.full_name,
                pract&.profession,
              ]
            end
          end
        end
      end

      private

      def calculate
        @result = {}
        @result[:invoices] = invoices_query

        @result[:invoices_count] = invoices_query.count

        paginated_invoices = invoices_query.page(options.page)
          .preload(:patient, :items, :appointment, :practitioner)
        @result[:paginated_invoices] = paginated_invoices

        @result[:products] = products_query
      end

      def invoices_query
        query = Invoice.where(business_id: business.id)
                        .includes(:patient, :items)
                        .where(issue_date: options.start_date..options.end_date)
                        .where(items: {invoiceable_type: 'Product' })

        if options.contact_ids && options.contact_ids.is_a?(Array)
          query = query.where(invoice_to_contact_id: options.contact_ids)
        end

        if options.practitioner_ids.present?
          query = query.where('invoices.practitioner_id' => options.practitioner_ids)
        end

        query.order(issue_date: :DESC)
      end
    end
  end
end
