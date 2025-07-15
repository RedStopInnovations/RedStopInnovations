module ClaimingApi
  module Apis
    module AuthGroup
      def create_auth_group(data)
        post('/auth_group/add', body: data.to_json)
      end
    end
  end
end
