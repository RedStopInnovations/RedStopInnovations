module Claiming
  class ProvidersRegistrationService
    def call(business, practitioner_ids)
      result = OpenStruct.new(
        success_practitioner_ids: [],
        failure_practitioner_ids: []
      )
      @business = business
      @practitioner_ids = practitioner_ids

      claiming_auth_group = @business.claiming_auth_group
      practitioners = Practitioner.where(id: practitioner_ids)

      api_client = ClaimingApi::Client.new

      practitioners.each do |pract|
        begin
          response = api_client.create_provider(
            claiming_auth_group.claiming_auth_group_id,
            {
              name: pract.full_name,
              providerNumber: pract.medicare,
              address1: pract.address1,
              address2: pract.address2,
              postcode: pract.postcode,
              state: pract.state
            }
          )
          if response.success?
            result.success_practitioner_ids << pract.id
            json_response = JSON.parse(response.body)
              ClaimingProvider.create(
                name: json_response['name'],
                provider_number: json_response['providerNumber'],
                auth_group_id: claiming_auth_group.id,
              )
          else
            result.failure_practitioner_ids << pract.id
          end
        rescue => e
          Sentry.capture_exception(e)
          result.failure_practitioner_ids << pract.id
        end
      end
      result
    end
  end
end
