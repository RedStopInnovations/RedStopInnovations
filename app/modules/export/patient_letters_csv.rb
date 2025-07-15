module Export
  class PatientLettersCsv
    class Options
      attr_accessor :start_date, :end_date, :letter_template_ids

      def initialize(options = {})
        @start_date = options[:start_date]
        @end_date = options[:end_date]
        @letter_template_ids = options[:letter_template_ids]
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
          'ID',
          'Client',
          'Client ID',
          'Author',
          'Letter template',
          'Description',
          'Creation',
        ]

        letters_query.includes(:author, :patient, :letter_template).find_each do |letter|
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

    private

    def letters_query
      query = PatientLetter.where(business_id: business.id)

      if options.start_date.present?
        query.where!('created_at >= ?', options.start_date.beginning_of_day)
      end

      if options.end_date.present?
        query.where!('created_at <= ?', options.end_date.end_of_day)
      end

      if options.letter_template_ids.present?
        query.where!(letter_template_id: options.letter_template_ids)
      end

      query
    end
  end
end
