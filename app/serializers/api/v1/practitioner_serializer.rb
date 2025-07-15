module Api
  module V1
    class PractitionerSerializer < BaseSerializer
      type 'practitioners'

      attributes  :first_name,
                  :last_name,
                  :active,
                  :education,
                  :profession,
                  :ahpra,
                  :medicare,
                  :phone,
                  :mobile,
                  :address1,
                  :address2,
                  :city,
                  :state,
                  :postcode,
                  :country,
                  :summary,
                  :updated_at,
                  :created_at,
                  :metadata

      attribute :avatar do
        @object.user.avatar.url if @object.user.avatar.exists?
      end

      attribute :email do
        @object.user.email
      end

      link :self do
        @url_helpers.api_v1_practitioner_url(@object.id)
      end
    end
  end
end
