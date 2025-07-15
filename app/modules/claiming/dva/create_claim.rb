module Claiming
  module Dva
    class CreateClaim
      attr_reader :business, :invoice

      def call(invoice)
        result = OpenStruct.new
        @invoice = invoice
        @business = invoice.business
        claiming_auth_group = business.claiming_auth_group

        claim_data = build_claim_data
        claim_response = claiming_api_client.create_claim(
          claiming_auth_group.claiming_auth_group_id,
          claim_data
        )
        if claim_response.success?
          json_response = JSON.parse(claim_response.body)
          store_claim(json_response)
          result.success = true
        else
          result.success = false
        end
        result
      end

      private

      def claiming_api_client
        @claiming_api_client ||= ClaimingApi::Client.new
      end

      def store_claim(raw_claim_info)
        claim = InvoiceClaim.dva.new(
          invoice: invoice,
          status: raw_claim_info['status'],
          claim_id: raw_claim_info['claimId'],
          medicare_claim_id: raw_claim_info['medicareClaimId'],
          transaction_id: raw_claim_info['transactionId']
        )
        claim.save!
        claim
      end

      def build_claim_data
        Claiming::Dva::ClaimData.new(invoice).data
      end
    end
  end
end
