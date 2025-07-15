module Statement
  class Filter
    attr_reader :type, :start_date, :end_date, :invoice_status, :patient_id

    def initialize(attrs)
      if attrs.key?(:type)
        @type = attrs[:type]
      else
        raise ArgumentError 'Statement type is required'
      end

      if attrs.key?(:start_date)
        @start_date = attrs[:start_date]
      else
        raise ArgumentError 'Start date filter is required'
      end

      if attrs.key?(:end_date)
        @end_date = attrs[:end_date]
      else
        raise ArgumentError 'End date filter is required'
      end

      @invoice_status = attrs[:invoice_status]
      @patient_id = attrs[:patient_id]
    end

    def to_h
      {
        start_date: start_date.strftime('%Y-%m-%d'),
        end_date: end_date.strftime('%Y-%m-%d'),
        invoice_status: invoice_status,
        patient_id: patient_id,
        type: type
      }.compact
    end
  end
end
