module RansackAuthorization
  module Invoice
    extend ActiveSupport::Concern

    included do

      def self.ransackable_attributes(auth_object = nil)
        [
          'invoice_number',
          'issue_date',
          'patient_id',
          'created_at',
          'updated_at',
        ]
      end

      def self.ransackable_associations(auth_object = nil)
        ['patient']
      end

      def self.ransortable_attributes(auth_object = nil)
        [
          'issue_date',
          'created_at',
          'updated_at'
        ]
      end
    end
  end
end
