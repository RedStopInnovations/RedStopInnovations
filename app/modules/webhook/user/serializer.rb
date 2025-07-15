module Webhook
  module User
    class Serializer
      attr_reader :user

      def initialize(user)
        @user = user
      end

      def as_json(options = {})
        attrs = user.attributes.symbolize_keys.slice(
          :id,
          :first_name,
          :last_name,
          :email,
          :role,
          :timezone,
          :updated_at,
          :created_at
        )
        attrs
      end
    end
  end
end