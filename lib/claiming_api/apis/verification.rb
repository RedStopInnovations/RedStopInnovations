module ClaimingApi
  module Apis
    module Verification
      def verify_patient(data)
        post('/verify', body: data.to_json)
      end
    end
  end
end
