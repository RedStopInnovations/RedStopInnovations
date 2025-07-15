module Webhook
  module Contact
    class Serializer

      attr_reader :contact

      def initialize(contact)
        @contact = contact
      end

      def as_json(options = {})
        attrs = contact.attributes.symbolize_keys.slice(
          :id,
          :business_name,
          :title,
          :first_name,
          :last_name,
          :phone,
          :mobile,
          :fax,
          :email,
          :address1,
          :address2,
          :city,
          :state,
          :postcode,
          :country,
          :notes,
          :deleted_at,
          :updated_at,
          :created_at
        )
        attrs
      end
    end
  end
end