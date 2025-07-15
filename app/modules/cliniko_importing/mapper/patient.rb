module ClinikoImporting
  module Mapper
    module Patient
      # @param cliniko_patient ClinikoApi::Resource::Patient
      def self.build(cliniko_patient)
        local_patient_attrs = {}
        {
          first_name: :first_name,
          last_name: :last_name,
          email: :email,
          date_of_birth: :dob,
          address_1: :address1,
          address_2: :address2,
          city: :city,
          post_code: :postcode,
          state: :state,
          gender: :gender,
          time_zone: :timezone,
          created_at: :created_at,
          updated_at: :updated_at,
          deleted_at: :deleted_at,
          archived_at: :archived_at
        }.each do |cliniko_field, local_field|
          local_patient_attrs[local_field] = cliniko_patient.send cliniko_field
        end

        if cliniko_patient.country.present?
          # `country` is country name in Cliniko
          local_patient_attrs[:country] =
            ISO3166::Country.find_country_by_any_name(cliniko_patient.country).try(:alpha2)
        end

        unless cliniko_patient.patient_phone_numbers.empty?
          cliniko_patient.patient_phone_numbers.each do |phone_number|
            if phone_number.phone_type == 'Mobile'
              local_patient_attrs[:mobile] = phone_number.number
              local_patient_attrs[:mobile_formated] = TelephoneNumber.parse(
                phone_number.number,
                local_patient_attrs[:country]
              ).international_number
            end

            if phone_number.phone_type == 'Home'
              local_patient_attrs[:phone] = phone_number.number
              local_patient_attrs[:phone_formated] = TelephoneNumber.parse(
                phone_number.number,
                local_patient_attrs[:country]
              ).international_number
            end
          end
        end

        if cliniko_patient.reminder_type == 'None'
          local_patient_attrs[:reminder_enable] = false
        end

        local_patient_attrs[:full_name] = [local_patient_attrs[:first_name].presence, local_patient_attrs[:last_name].presence].compact.join(' ')

        # @TODO: check merged_a to fill archived_at
        general_info_lines = []

        if cliniko_patient.notes.to_s.strip.present?
          general_info_lines << "Notes: #{cliniko_patient.notes.strip}"
        end

        if cliniko_patient.appointment_notes.to_s.strip.present?
          general_info_lines << "Appointment notes: #{cliniko_patient.appointment_notes.strip}"
        end

        if cliniko_patient.medicare.to_s.strip.present?
          general_info_lines << "Medicare: #{cliniko_patient.medicare.strip}"
        end

        if cliniko_patient.medicare_reference_number.to_s.strip.present?
          general_info_lines << "Medicare reference number: #{cliniko_patient.medicare_reference_number.strip}"
        end

        if cliniko_patient.dva_card_number.to_s.strip.present?
          general_info_lines << "DVA card number: #{cliniko_patient.dva_card_number.strip}"
        end

        if cliniko_patient.invoice_extra_information.to_s.strip.present?
          general_info_lines << "Invoice extra info: #{cliniko_patient.invoice_extra_information.strip}"
        end

        if cliniko_patient.referral_source.to_s.strip.present?
          general_info_lines << "Referral source: #{cliniko_patient.referral_source.strip}"
        end

        if cliniko_patient.occupation.to_s.strip.present?
          general_info_lines << "Occupation: #{cliniko_patient.occupation.strip}"
        end

        if general_info_lines.present?
          local_patient_attrs[:general_info] = general_info_lines.join("\n\n")
        end

        %i(address1 address2 city state postcode country).each do |nullify_empty_attr|
          local_patient_attrs[nullify_empty_attr] = local_patient_attrs[nullify_empty_attr].to_s.strip.presence
        end

        local_patient_attrs
      end
    end
  end
end
