module Report
  module Contacts
    class AccountStatements

      attr_reader :business, :options, :result

      class Options
        attr_accessor :search, :start_date, :end_date, :contact_ids, :payment_status, :page

        def initialize(attrs = {})
          @search = attrs[:search]
          @start_date = attrs[:start_date]
          @end_date = attrs[:end_date]
          @payment_status = attrs[:payment_status]
          @contact_ids = attrs[:contact_ids]
          @page = attrs[:page]
        end
      end

      def initialize(business, options)
        @business = business
        @options = options
        calculate
      end

      def self.make(business, options)
        new(business, options)
      end

      private

      def calculate
        @result = {}

        query = ::AccountStatement.
          joins('LEFT JOIN contacts ON contacts.id = account_statements.source_id').
          where(account_statements: {
            deleted_at: nil,
            source_type: ::Contact.name
          }).
          where('contacts.business_id' => business.id).
          includes(:source).
          order(created_at: :desc)

        if options.search.present?
          query.where!('LOWER(account_statements.number) LIKE ?', "%#{options.search.to_s.downcase}%")
        end

        if options.contact_ids.present?
          query.where!(account_statements: {
            source_id: options.contact_ids
          })
        end

        if options.start_date
          query.where!('account_statements.created_at >= ?', options.start_date.beginning_of_day)
        end

        if options.end_date
          query.where!('account_statements.created_at <= ?', options.end_date.end_of_day)
        end

        query = query.left_joins(:invoices)
          .where(invoices: { deleted_at: nil })

        query = query.select(
          'account_statements.*',
          'COALESCE(SUM(invoices.outstanding), 0) AS total_invoices_outstanding',
          'COALESCE(SUM(invoices.amount), 0) AS total_invoices_amount'
        )

        if options.payment_status.present?
          case options.payment_status
          when 'paid'
            query = query.having('SUM(invoices.outstanding) = 0')
          when 'outstanding'
            query = query.having('SUM(invoices.outstanding) > 0')
          end
        end

        query.group!('account_statements.id')

        @result[:paginated_account_statements] = query.page(options.page)
      end
    end
  end
end
