module ClaimingApi
  module Apis
    module Provider

      def create_provider(auth_group_id, data)
        post("/provider/add?auth_group=#{auth_group_id}", body: data.to_json)
      end

      def list_provider(auth_group_id)
        get("/provider/list?auth_group=#{auth_group_id}")
      end

      def update_provider
        post("/provider/update?auth_group=#{auth_group_id}", body: data.to_json)
      end
    end
  end
end
