module Report
  module Contacts
    class TotalInvoices
      class Options
        attr_accessor :start_date, :end_date, :contact_ids, :page

        def initialize(attrs = {})
          @start_date = attrs[:start_date]
          @end_date = attrs[:end_date]
          @contact_ids = attrs[:contact_ids]
          @page = attrs[:page]
        end

        def to_param
          params = {}
          params[:contact_ids] = contact_ids if contact_ids.present?

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
          csv << ["Contact", "Contact name", "Number of invoices", "Total invoiced amount"]

          @result[:contacts].each do |contact|
            csv << [
              contact.business_name,
              contact.full_name,
              contact.invoices_count,
              contact.invoiced_amount.to_f.round(2).to_s
            ]
          end
        end
      end

      private

      def calculate
        @result = {}

        contacts_query = business.contacts.joins('INNER JOIN invoices ON invoices.invoice_to_contact_id = contacts.id').
          select(:id, :first_name, :last_name, :full_name, :business_name).
          select('SUM(invoices.amount) AS invoiced_amount, COUNT(invoices.id) AS invoices_count').
          where('invoices.issue_date' => options.start_date..options.end_date).
          order('invoiced_amount DESC').
          group('contacts.id')


        invoices_query = business.invoices.
          where('invoices.issue_date' => options.start_date..options.end_date).
          where('invoice_to_contact_id IS NOT NULL')

        if options.contact_ids.present?
          contacts_query = contacts_query.where('contacts.id' => options.contact_ids)
          invoices_query = invoices_query.where(invoice_to_contact_id: options.contact_ids)
        end

        @result[:contacts] = contacts_query
        @result[:paginated_contacts] = contacts_query.page(options.page)
        @result[:total_invoiced_amount] = invoices_query.sum(:amount)
        @result[:invoices_count] = invoices_query.count
      end
    end
  end
end
