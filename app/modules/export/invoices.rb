module Export
  class Invoices
    class Options
      attr_accessor :start_date,
                    :end_date,
                    :practitioner_ids,
                    :patient_ids,
                    :contact_ids,
                    :payment_status,
                    :delivery_status

      def initialize(options = {})
        options.symbolize_keys!

        @start_date = options[:start_date]
        @end_date = options[:end_date]
        @practitioner_ids = options[:practitioner_ids]
        @patient_ids = options[:patient_ids]
        @contact_ids = options[:contact_ids]
        @payment_status = options[:payment_status]
        @delivery_status = options[:delivery_status]
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
      invoices_query.count
    end

    def items
      invoices_query.load
    end

    def items_query
      invoices_query
    end

    private

    def invoices_query
      query = Invoice.where(business_id: business.id).where("invoices.deleted_at IS NULL")
        .joins(:patient).where("patients.deleted_at IS NULL")

      if options.start_date.present?
        query = query.where('issue_date >= ?', options.start_date)
      end

      if options.end_date.present?
        query = query.where('issue_date <= ?', options.end_date)
      end

      if options.practitioner_ids.present?
        query = query.joins(:appointment)
                     .where('appointments.practitioner_id' => options.practitioner_ids)
      end

      if options.patient_ids.present?
        query = query.where('invoices.patient_id' => options.patient_ids)
      end

      if options.contact_ids.present?
        query = query.where('invoices.invoice_to_contact_id' => options.contact_ids)
      end

      if options.payment_status.present?
        case options.payment_status
        when 'outstanding'
          query = query.where('invoices.outstanding > 0')
        when 'paid'
          query = query.where('invoices.outstanding = 0')
        end
      end

      if options.delivery_status.present?
        case options.delivery_status
        when 'sent'
          query = query.where('invoices.last_send_at IS NOT NULL')
        when 'unsent'
          query = query.where("invoices.last_send_at IS NULL")
        end
      end

      query.order('invoices.id ASC')
    end
  end
end
