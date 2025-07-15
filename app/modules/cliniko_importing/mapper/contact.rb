module ClinikoImporting
  module Mapper
    module Contact
      # @param cliniko_contact ClinikoApi::Resource::Contact
      def self.build(cliniko_contact)
        local_contact_attrs = {}
        {
          first_name: :first_name,
          last_name: :last_name,
          email: :email,

          address_1: :address1,
          address_2: :address2,
          city: :city,
          post_code: :postcode,
          state: :state,
          country_code: :country,

          created_at: :created_at,
          updated_at: :updated_at,
          deleted_at: :deleted_at
          # @TODO: what about archived_at ?
        }.each do |cliniko_field, local_field|
          local_contact_attrs[local_field] = cliniko_contact.send cliniko_field
        end

        if cliniko_contact.phone_numbers.present?
          cliniko_contact.phone_numbers.each do |phone_number|
            if phone_number.phone_type == 'Mobile'
              local_contact_attrs[:mobile] = phone_number.number
            end

            if phone_number.phone_type == 'Home'
              local_contact_attrs[:phone] = phone_number.number
            end
          end
        end

        local_contact_attrs[:full_name] = [local_contact_attrs[:first_name].presence, local_contact_attrs[:last_name].presence].compact.join(' ')

        local_contact_attrs[:business_name] =
          if cliniko_contact.preferred_name.present?
            cliniko_contact.preferred_name
          elsif cliniko_contact.company_name.present?
            cliniko_contact.company_name
          else
            local_contact_attrs[:full_name]
          end

        %i(address1 address2 city state postcode country).each do |nullify_empty_attr|
          local_contact_attrs[nullify_empty_attr] = local_contact_attrs[nullify_empty_attr].to_s.strip.presence
        end

        notes_parts = []

        if cliniko_contact.doctor_type.present?
          notes_parts << "Doctor type: #{cliniko_contact.doctor_type}"
        end

        if cliniko_contact.provider_number.present?
          notes_parts << "Provider number: #{cliniko_contact.provider_number}"
        end

        if cliniko_contact.occupation.present?
          notes_parts << "Occupation: #{cliniko_contact.occupation}"
        end

        if cliniko_contact.notes.to_s.strip.present?
          notes_parts << cliniko_contact.notes.strip
        end

        if notes_parts.present?
          local_contact_attrs[:notes] = notes_parts.join("\n\n")
        end

        local_contact_attrs
      end
    end
  end
end
