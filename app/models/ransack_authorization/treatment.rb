module RansackAuthorization
  module Treatment
    extend ActiveSupport::Concern

    included do

      def self.ransackable_attributes(auth_object = nil)
        _ransackers.keys + [
          'name',
          'status',
          'patient_id',
          'author_id',
          'created_at',
          'updated_at'
        ]
      end

      def self.ransackable_associations(auth_object = nil)
        ['patient']
      end

      def self.ransortable_attributes(auth_object = nil)
        [
          'first_name',
          'last_name',
          'status',
          'created_at',
          'updated_at'
        ]
      end
    end
  end
end
