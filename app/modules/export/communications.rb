module Export
  class Communications

    class Options
      attr_accessor :start_date, :end_date, :recipient_type, :category, :message_type, :delivery_status

      def initialize(options = {})
        @start_date = options[:start_date]
        @end_date = options[:end_date]
        @category = options[:category]
        @message_type = options[:message_type]
        @delivery_status = options[:delivery_status]
        @recipient_type = options[:recipient_type]
      end
    end

    attr_reader :business, :options

    def self.make(business, options)
      new(business, options)
    end

    def initialize(business, options)
      @business = business
      @options = options
    end

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << [
          'Category',
          'Recipient ID',
          'Recipient type',
          'Client ID',
          'Delivery method',
          'Destination',
          'Delivery status',
          'Send at',
        ]

        communications_query.includes(:delivery).find_each do |com|
          delivery = com.delivery
          csv << [
            com.category? ? I18n.t("communication.categories.#{com.category}") : '',
            com.recipient_id,
            com.recipient_type == 'Patient' ? 'Client' : com.recipient_type,
            com.linked_patient_id,
            com.message_type,
            delivery.present? ? delivery.recipient : '',
            delivery.present? ? delivery.status.titleize : 'Unknown',
            com.created_at.strftime(I18n.t('datetime.common')),
          ]
        end
      end
    end

    private

    def communications_query
      query = Communication.where(business_id: business.id)

      if options.start_date.present?
        query = query.where('created_at >= ?', options.start_date.beginning_of_day)
      end

      if options.end_date.present?
        query = query.where('created_at <= ?', options.end_date.end_of_day)
      end

      if options.recipient_type.present?
        query = query.where(recipient_type: options.recipient_type)
      end

      if options.category.present?
        query = query.where(category: options.category)
      end

      if options.message_type.present?
        query = query.where(message_type: options.message_type)
      end

      if options.delivery_status.present?
        query = query.joins(:delivery).where(delivery: {status: options.delivery_status})
      end

      query.order(id: :asc)

      query
    end
  end
end
