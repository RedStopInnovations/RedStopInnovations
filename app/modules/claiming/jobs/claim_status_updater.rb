module Claiming
  module Jobs
    # Cron job to update Medicare & DVA claims status
    class ClaimStatusUpdater < ApplicationJob
      def perform
        api_client = ClaimingApi::Client.new

        InvoiceClaim.
          not_final_status.
          includes(invoice: [business: :claiming_auth_group]).
          find_each do |claim|
            invoice = claim.invoice
            business = invoice.business
            claiming_auth_group = business.claiming_auth_group

            if claiming_auth_group
              begin
                response = api_client.find_claim(
                  claiming_auth_group.claiming_auth_group_id,
                  claim.claim_id
                )
                if response.success?
                  json_response = JSON.parse(response.body)
                  if claim.status != json_response['status']
                    claim.update_attribute :status, json_response['status']
                  end
                end
              rescue => e
                Sentry.capture_exception(e)
              end
            end
          end
      end
    end
  end
end
