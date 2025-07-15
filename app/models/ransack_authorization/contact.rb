module RansackAuthorization
  module Contact
    extend ActiveSupport::Concern

    included do

      def self.ransackable_attributes(auth_object = nil)
        _ransackers.keys + [
          'id',
          'business_name',
          'first_name',
          'last_name',
          'full_name',
          'email',
          'phone',
          'mobile',
          'created_at',
          'updated_at'
        ]
      end

      def self.ransackable_associations(auth_object = nil)
        []
      end

      def self.ransortable_attributes(auth_object = nil)
        [
          'business_name',
          'created_at',
          'updated_at'
        ]
      end
    end
  end
end
