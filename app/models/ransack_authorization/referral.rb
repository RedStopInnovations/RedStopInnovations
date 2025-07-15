module RansackAuthorization
  module Referral
    extend ActiveSupport::Concern

    included do

      def self.ransackable_attributes(auth_object = nil)
        _ransackers.keys + [
          'id',
          'referrer_business_name',
          'referrer_name',
          'referrer_email',
          'referrer_phone',
          'status',
          'created_at',
          'updated_at'
        ]
      end

      def self.ransackable_associations(auth_object = nil)
        []
      end
    end
  end
end
