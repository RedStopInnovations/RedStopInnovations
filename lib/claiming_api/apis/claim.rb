module ClaimingApi
  module Apis
    module Claim
      def create_claim(auth_group_id, claim_data)
        post("/claim?auth_group=#{auth_group_id}", body: claim_data.to_json)
      end

      def find_claim(auth_group_id, claim_id)
        get("/claim/#{claim_id}?auth_group=#{auth_group_id}")
      end

      def simulate_claim_process(auth_group_id, claim_id, options = {})
        get("/claim/#{claim_id}/simulate/processing?auth_group=#{auth_group_id}")
      end

      def simulate_claim_payment(auth_group_id, claim_ids)
        post("/payment/simulate?auth_group=#{auth_group_id}&claims=#{claim_ids.join(',')}")
      end
    end
  end
end
