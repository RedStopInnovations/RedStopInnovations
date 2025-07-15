module Bookings
  module Search
    class Filters
      include Virtus.model
      include ActiveModel::Model

      attribute :country, String
      attribute :availability_type, String, default: 'Home visit'
      attribute :profession, String
      attribute :date, String, default: 'next7days'

      attribute :location, String
      attribute :page, Integer, default: 1

      # Reserved filters
      attribute :business_id, Integer
      attribute :practitioner_id, Integer
      attribute :group_id, Integer
      attribute :online_bookings_enable, Boolean, default: false

      validates :availability_type,
                inclusion: { in: ['Home visit'] },
                allow_nil: true,
                allow_blank: true

      validate do
        if business_id.present? && !Business.exists?(id: business_id)
          errors.add(:base, 'Business does not exist')
        end

        if practitioner_id.present? && !Practitioner.exists?(id: practitioner_id)
          errors.add(:base, 'Practitioner does not exist')
        end

        if group_id.present? && !Group.exists?(id: group_id)
          errors.add(:base, 'Practitioner group does not exist')
        end
      end

      def to_param
        attributes.compact
      end

      def home_visit?
        availability_type == 'Home visit'
      end

      def business
        @business ||= begin
          if business_id.present?
            Business.find_by(id: business_id)
          elsif practitioner_id.present?
            Practitioner.find_by(id: practitioner_id).try(:business)
          elsif group_id.present?
            Group.find_by(id: group_id).try(:business)
          end
        end
      end
    end
  end
end
