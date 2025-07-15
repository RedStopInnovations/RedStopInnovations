module Bookings
  module Search
    class FacilityBookingsFilter
      include Virtus.model
      include ActiveModel::Model

      attribute :page, Integer, default: 1

      # Reserved filters
      attribute :business_id, Integer
      attribute :contact_id, Integer

      # Additional filters
      attribute :practitioner_id, Integer
      attribute :profession, String
      attribute :date, String, default: 'next14days'

      def to_param
        attributes.compact
      end

      def valid?
        business_id.present? &&
        contact_id.present? &&
        business.present? &&
        contact.present?
      end

      def business
        @business ||= Business.find_by(id: business_id)
      end

      def contact
        @contact ||= begin
          if business
            business.contacts.find_by(id: contact_id)
          end
        end
      end
    end
  end
end
