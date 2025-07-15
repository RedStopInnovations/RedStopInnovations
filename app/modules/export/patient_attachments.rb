module Export
  class PatientAttachments
    class Options
      attr_accessor :start_date,
                    :end_date,
                    :patient_ids

      def initialize(options = {})
        options.symbolize_keys!

        @start_date = options[:start_date]
        @end_date = options[:end_date]
        @patient_ids = options[:patient_ids]
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
      patient_attachments_query.count
    end

    def items
      patient_attachments_query.load
    end

    def items_query
      patient_attachments_query
    end

    private

    def patient_attachments_query
      query = PatientAttachment.
        joins(:patient).
        includes(:patient).
        where('patients.business_id = ?', business.id).
        where("patients.deleted_at IS NULL")

      if options.start_date.present?
        query = query.where('patient_attachments.created_at >= ?', options.start_date.to_date.beginning_of_day)
      end

      if options.end_date.present?
        query = query.where('patient_attachments.created_at <= ?', options.end_date.to_date.end_of_day)
      end

      if options.patient_ids.present?
        query = query.where('patients.id' => options.patient_ids)
      end

      query
    end
  end
end
