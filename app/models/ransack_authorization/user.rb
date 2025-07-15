module RansackAuthorization
  module User
    extend ActiveSupport::Concern

    included do

      def self.ransackable_attributes(auth_object = nil)
        [
          'id',
          'first_name',
          'last_name',
          'full_name',
          'email',
          'role',
          'created_at',
          'updated_at'
        ]
      end

      def self.ransackable_associations(auth_object = nil)
        ['business']
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
