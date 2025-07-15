module Claiming
  class CreateAuthGroupService
    attr_reader :business, :form

    def call(business, form)
      result = OpenStruct.new
      @business = business
      @form = form
      response = ClaimingApi::Client.new.create_auth_group(build_auth_group_data)

      if response.success?
        json_response = JSON.parse(response.body)
        auth_group = store_auth_group(json_response)
        result.success = true
      else
        result.success = false
        result.error = 'An error has occurred.'
      end

      result
    end

    private

    def build_auth_group_data
      data = {
        name: form.name
      }

      unless form.practitioner_ids.blank?
        data[:providers] = []
        business.practitioners.active.where(id: form.practitioner_ids).each do |pract|
          data[:providers] << {
            name: pract.full_name,
            providerNumber: pract.medicare,
            address1: pract.address1,
            address2: pract.address2,
            postcode: pract.postcode,
            state: pract.state
          }
        end
      end

      data
    end

    def store_auth_group(raw_auth_group_info)
      group = nil
      ApplicationRecord.transaction do
        group = ClaimingAuthGroup.create!(
          business_id: business.id,
          claiming_auth_group_id: raw_auth_group_info['id'],
          claiming_minor_id: raw_auth_group_info['minorID']
        )
        if raw_auth_group_info['providers']
          raw_auth_group_info['providers'].each do |provider|
            ClaimingProvider.create(
              name: provider['name'],
              provider_number: provider['providerNumber'],
              auth_group_id: group.id
            )
          end
        end
      end

      group
    end
  end
end
