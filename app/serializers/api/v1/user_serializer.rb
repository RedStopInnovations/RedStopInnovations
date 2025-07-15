module Api
  module V1
    class UserSerializer < BaseSerializer
      type 'users'

      attributes  :first_name,
                  :last_name,
                  :email,
                  :role,
                  :timezone,
                  :updated_at,
                  :created_at

      attribute :avatar do
        @object.avatar.url if @object.avatar.exists?
      end

      link :self do
        @url_helpers.api_v1_user_url(@object.id)
      end
    end
  end
end
