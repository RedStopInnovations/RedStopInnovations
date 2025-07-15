module RansackAuthorization
  module Patient
    extend ActiveSupport::Concern

    included do

      def self.ransackable_attributes(auth_object = nil)
        _ransackers.keys + [
          'id',
          'first_name',
          'last_name',
          'full_name',
          'dob',
          'phone',
          'mobile',
          'email',
          'city',
          'state',
          'postcode',
          'created_at',
          'updated_at'
        ]
      end

      def self.ransackable_associations(auth_object = nil)
        []
      end

      def self.ransortable_attributes(auth_object = nil)
        [
          'first_name',
          'last_name',
          'full_name',
          'created_at',
          'updated_at'
        ]
      end
    end
  end
end
