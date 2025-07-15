module Export
  class AttendanceProof
    class Options
      attr_accessor :invoice_id, :account_statement_id

      def initialize(options = {})
        options.symbolize_keys!

        @account_statement_id = options[:account_statement_id]
        @invoice_id = options[:invoice_id]
      end
    end

    attr_reader :business, :options

    def self.make(business, options)
      new(business)
    end

    def initialize(business, options)
      @business = business
      @options = options
    end

    def items_count
      appointments_query.count
    end

    def items
      appointments_query.load
    end

    private

    def appointments_query
      query = Appointment.none

      if options.account_statement_id.present?
        account_statement = business.account_statements.find_by(id: options.account_statement_id)
        if account_statement
          query = account_statement.appointments.includes(:patient, :practitioner, :appointment_type)
        end
      elsif options.invoice_id.present?
        invoice = business.invoices.find_by(id: options.invoice_id)
        if invoice && invoice.appointment_id
          query = business.appointments.where(id: invoice.appointment_id)
        end
      end

      query
    end
  end
end