module Export
  class PatientLetters
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

    def to_csv
      CSV.generate(headers: true) do |csv|
        csv << [
          'ID',
          'Client',
          'Client ID',
          'Author',
          'Letter template',
          'Description',
          'Creation',
        ]

        items_query.includes(:author, :patient, :letter_template).find_each do |letter|
          csv << [
            letter.id,
            letter.patient&.full_name,
            letter.patient&.id,
            letter.author&.full_name,
            letter.letter_template&.name,
            letter.description,
            letter.created_at.strftime('%Y-%m-%d'),
          ]
        end
      end
    end

    def items_query
      query = PatientLetter.where(business_id: business.id)

      if options.start_date.present?
        query.where!('created_at >= ?', options.start_date.to_date.beginning_of_day)
      end

      if options.end_date.present?
        query.where!('created_at <= ?', options.end_date.to_date.end_of_day)
      end

      if options.template_ids.present?
        query.where!(letter_template_id: options.template_ids)
      end

      query
    end
  end
end
