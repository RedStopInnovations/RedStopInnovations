module Api
  module V1
    class BusinessSerializer < BaseSerializer
      type 'businesses'

      attributes :name,
                :phone,
                :mobile,
                :website,
                :fax,
                :email,
                :address1,
                :address2,
                :city,
                :state,
                :postcode,
                :country,
                :bank_name,
                :bank_branch_number,
                :bank_account_name,
                :bank_account_number,
                :abn

      attribute :logo do
        @object.avatar.url if @object.avatar.exists?
      end

      link :self do
        @url_helpers.api_v1_business_url
      end
    end
  end
end
