module Api
  module V1
    class ContactSerializer < BaseSerializer
      type 'contacts'

      attributes  :business_name,
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
                  :created_at,
                  :metadata
      link :self do
        @url_helpers.api_v1_contact_url(@object.id)
      end
    end
  end
end
