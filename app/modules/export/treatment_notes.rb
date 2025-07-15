module Export
  class TreatmentNotes
    attr_reader :business, :options

    class Options
      attr_accessor :start_date, :end_date, :template_ids, :status

      def initialize(options_h = {})
        options_h.symbolize_keys!

        @start_date = options_h[:start_date]
        @end_date = options_h[:end_date]
        @status = options_h[:status]
        @template_ids = options_h[:template_ids]
      end
    end

    def initialize(business, options)
      @business = business
      @options = options
    end

    def items_query
      query = business.patient_treatments

      if options.start_date.present?
        query = query.where("treatments.created_at >= ?", options.start_date.to_date.beginning_of_day)
      end

      if options.end_date.present?
        query = query.where("treatments.created_at <= ?", options.end_date.to_date.end_of_day)
      end

      if options.template_ids.present?
        query = query.where("treatments.treatment_template_id" => options.template_ids)
      end

      if options.status.present?
        query = query.where("treatments.status" => options.status)
      end

      query
    end
  end
end
