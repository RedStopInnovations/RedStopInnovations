module Report
  module Contacts
    class PatientContacts
      attr_reader :business, :results, :options

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        calculate
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << ["ID", "Name", "Total associates"]

          @results.each do |row|
            csv << [
              row['id'],
              row['business_name'],
              row['patients_count'],
            ]
          end
        end
      end

      private

      def calculate
        @results ||= business.patients.joins(:patient_contacts)
            .joins("INNER JOIN contacts ON contacts.id = patient_contacts.contact_id")
            .select("contacts.id, contacts.business_name, COUNT(*) AS patients_count")

        if PatientContact::TYPES.include?(options[:type])
          @results = @results.where("patient_contacts.type": options[:type])
        end

        options[:start_date] = options[:start_date].try(:to_date)
        options[:end_date] = options[:end_date].try(:to_date)

        @results = @results.where("patient_contacts.created_at >= ?", options[:start_date].beginning_of_day) if options[:start_date]
        @results = @results.where("patient_contacts.created_at <= ?", options[:end_date].end_of_day) if options[:end_date]

        @results = @results.where(contacts: {id: options[:contact_ids]}) if options[:contact_ids].present?

        @results = @results.group("contacts.id").order("patients_count DESC")

        @results
      end
    end
  end
end
