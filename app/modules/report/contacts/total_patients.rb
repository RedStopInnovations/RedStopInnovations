module Report
  module Contacts
    class TotalPatients
      class Options
        attr_accessor :contact_ids, :page

        def initialize(attrs = {})
          @contact_ids = attrs[:contact_ids]
          @page = attrs[:page]
        end

        def to_param
          params = {}
          params[:contact_ids] = contact_ids if contact_ids.present?
          params
        end
      end

      attr_reader :business, :result, :options

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

          result[:contacts].each do |contact|
            csv << [
              contact.id,
              contact.business_name,
              contact.patients_count
            ]
          end
        end
      end

      private

      def calculate
        @result = {}

        query = business.contacts.
          joins(:patient_contacts).
          select("contacts.id, contacts.business_name, COUNT(DISTINCT patient_contacts.patient_id) AS patients_count").
          group("contacts.id").
          order("patients_count DESC")

        if options.contact_ids.present?
          query = query.where(contacts: { id: options.contact_ids })
        end

        @result[:contacts] = query
        @result[:paginated_contacts] = query.page(options.page)
      end
    end
  end
end
