module Export
  class Contacts
    attr_reader :business, :options

    def self.make(business, options)
      new(business, options)
    end

    def initialize(business, options)
      @business = business
      @options = options
    end

    def as_csv
      CSV.generate(headers: true) do |csv|
        csv << [
          'ID', 'Business name', 'First name', 'Last name', 'Email', 'Phone', 'Mobile',
          'Address line 1', 'Address line 2', 'City', 'State', 'Postcode', 'Country', 'Creation', 'Clients ID', 'Notes'
        ]

        contacts_query.load.each do |contact|
          csv << [
            contact.id,
            contact.business_name,
            contact.first_name,
            contact.last_name,
            contact.email,
            contact.phone,
            contact.mobile,
            contact.address1,
            contact.address2,
            contact.city,
            contact.state,
            contact.postcode,
            contact.country,
            contact.created_at.strftime('%Y-%m-%d'),
            contact.patient_ids.join(';'),
            contact.notes
          ]
        end
      end
    end

    private

    def contacts_query
      query = business.contacts

      if options[:start_date].present?
        query = query.where("created_at >= ?", options[:start_date].beginning_of_day)
      end
      if options[:end_date].present?
        query = query.where("created_at <= ?", options[:end_date].end_of_day)
      end

      query.includes(:patients).order(created_at: :asc)
    end
  end
end
