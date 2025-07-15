module Export
  class AccountStatements
    attr_reader :business, :options, :result

    class Options
      attr_accessor :start_date, :end_date, :source_type, :source_ids, :payment_status

      def initialize(options_h = {})
        options_h.symbolize_keys!

        @source_type = options_h[:source_type]
        @start_date = options_h[:start_date]
        @end_date = options_h[:end_date]
        @payment_status = options_h[:payment_status]
        @source_ids = options_h[:source_ids]
      end
    end

    def initialize(business, options)
      @business = business
      @options = options
    end

    def items_query
      @result = {}

      query = ::AccountStatement
        .where(account_statements: {
          deleted_at: nil,
          business_id: business.id,
          source_type: options.source_type
        })

      if options.source_ids.present?
        query.where!(source_id: options.source_ids)
      end

      if options.start_date
        query.where!('account_statements.created_at >= ?', options.start_date.to_date.beginning_of_day)
      end

      if options.end_date
        query.where!('account_statements.created_at <= ?', options.end_date.to_date.end_of_day)
      end

      query = query.left_joins(:invoices)
        .where(invoices: { deleted_at: nil })
        .select(
        'account_statements.*'
      )

      if options.payment_status.present?
        case options.payment_status
        when 'paid'
          query.having!('SUM(invoices.outstanding) = 0')
        when 'outstanding'
          query.having!('SUM(invoices.outstanding) > 0')
        end
      end

      query.group!('account_statements.id')
    end
  end
end
