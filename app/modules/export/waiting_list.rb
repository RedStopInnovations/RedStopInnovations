module Export
  class WaitingList
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
          'ID', 'Date', 'Profession', 'Appointment type', 'Practitioner', 'Scheduled', 'Notes',
          "Client ID", "Client", "Client first name", "Client last name", "Client dob", "Client mobile", "Client phone", "Client email",
          "Client address line 1", "Client address line 2", "Client city", "Client state", "Client postcode", "Client country",
          'Creation'
        ]

        query = wait_list_query
          .includes(:patient, :practitioner, :appointment_type)
          .find_each do |item|
            csv << [
              item.id,

              item.date.strftime('%Y-%m-%d'),
              item.profession.presence,
              item.appointment_type&.name,
              item.practitioner&.full_name,
              item.scheduled? ? 'Yes' : 'No',
              item.notes.presence,

              item.patient.id,
              item.patient.full_name,
              item.patient.first_name,
              item.patient.last_name,
              item.patient.dob,
              item.patient.mobile,
              item.patient.phone,
              item.patient.email,

              item.patient.address1,
              item.patient.address2,
              item.patient.city,
              item.patient.state,
              item.patient.postcode,
              item.patient.country,

              item.created_at.strftime('%Y-%m-%d')
            ]
        end
      end
    end

    private

    def wait_list_query
      query = business.wait_lists

      unless options[:include_scheduled].present?
        query = query.not_scheduled
      end

      if options[:date_start].present?
        query = query.where("date >= ?", options[:date_start])
      end

      if options[:date_end].present?
        query = query.where("date <= ?", options[:date_end])
      end

      if options[:professions].present?
        query = query.where(profession: options[:professions])
      end

      query = query.joins(:patient).where(patients: {archived_at: nil, deleted_at: nil})

      query.order(date: :asc)
    end
  end
end
