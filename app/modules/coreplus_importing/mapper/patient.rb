module CoreplusImporting
  module Mapper
    module Patient
=begin
  Coreplus field                           Local column | sample value
  ----------------------------------------------------------------------
  "clientID": "1690370",                   N/A
  "createDate": "4/03/2016",               created_at
  "title": null,                           N/I
  "name": "Vito",                          first_name
  "surname": "Lombardo",                   last_name
  "DOB": "10/04/1933",                     dob
  "gender": null,                          gender       | Male, Female
  "address": "17 Cabarita Road",           address1
  "suburb": "Cabarita",                    city
  "postcode": null,                        postcode
  "samePostalAddress": "0",                N/I
  "postalAddress": null,                   N/I
  "postalSuburb": null,                    N/I
  "postalPostcode": null,                  N/I
  "homeNo": "297507293",                   phone
  "mobile": null,                          mobile
  "workNo": null,                          phone
  "faxNo": null,                           fax
  "email": null,                           email
  "referrer": null,                        N/I
  "dateReferred": null,                    N/I
  "referralExpiry": null,                  N/I
  "caseStatus": "CURRENT",                 N/I
  "disclosure": null,                      N/I
  "site": "Private Visit",                 N/I
  "caseManager": "Lyndal Millikan",        N/I
  "medicareCardNumber": null,              medicare_card_number
  "medicareCardIRN": null,                 medicare_card_irn
  "medicareCardExpireDate": null,          N/I
  "DVAnumber": null,                       dva_file_number
  "clientGroup": "General",                N/I
=end
      # Notes:
      # - Country fixed to AU
      # - City & state are not available. Use google API to parse address. Maybe API calls limit issue.
      # - Medicare & DVA numbers seems not to be valid values.
      def self.build(coreplus_attrs)
        local_attrs = {
          first_name: coreplus_attrs['name'].to_s.strip.presence,
          last_name: coreplus_attrs['surname'].to_s.strip.presence,
          gender: coreplus_attrs['gender'].presence,
          country: 'AU',
          email: coreplus_attrs['email'].presence,
          medicare_card_number: coreplus_attrs['medicareCardNumber'].presence,
          medicare_card_irn: coreplus_attrs['medicareCardIRN'].presence,
          dva_file_number: coreplus_attrs['DVAnumber'].presence,
          created_at: coreplus_attrs['createDate'].to_time,
          updated_at: Time.current
        }
        local_attrs[:dob] = Date.parse(coreplus_attrs['DOB']) rescue nil

        general_info_lines = []

        if coreplus_attrs['workNumber'].present?
          general_info_lines << "work number: #{coreplus_attrs['workNumber']}"
        end
        if coreplus_attrs['caseManager'].present?
          general_info_lines << "case manager: #{coreplus_attrs['caseManager']}"
        end

        if coreplus_attrs['site'].present?
          general_info_lines << "site: #{coreplus_attrs['site']}"
        end
        if coreplus_attrs['clientGroup'].present?
          general_info_lines << "client group: #{coreplus_attrs['clientGroup']}"
        end

        case_status = coreplus_attrs['caseStatus'].presence
        if case_status.present?
          if ['closed', 'deceased'].include?(case_status.downcase)
            local_attrs[:archived_at] = Time.current
          end
        end

        if general_info_lines.present?
          local_attrs[:general_info] = general_info_lines.join("\n")
        end

        local_attrs[:full_name] = [
          local_attrs[:first_name],
          local_attrs[:last_name]
        ].compact.join(' ')

        address = coreplus_attrs['address'].presence
        if address
          # Parse address
          full_address = [
            coreplus_attrs['address'],
            coreplus_attrs['suburb'],
            coreplus_attrs['postcode']
          ].compact.join(', ') << " Australia"
          results = Geocoder.search(full_address)

          if results.present?
            result = results.first
            address1_cmpts = []
            address2 = nil
            result.data['address_components'].each do |addr_cmpt|
              if addr_cmpt['types'].include?('street_number') || addr_cmpt['types'].include?('route')
                address1_cmpts << addr_cmpt['long_name']
              end

              if addr_cmpt['types'].include?('premise')
                address2 = addr_cmpt['long_name']
              end

              # State
              if addr_cmpt['types'].include?('administrative_area_level_1')
                local_attrs[:state] = addr_cmpt['short_name']
              end

              # Postcode
              if addr_cmpt['types'].include?('postal_code')
                local_attrs[:postcode] = addr_cmpt['short_name']
              end

              # City
              if addr_cmpt['types'].include?('locality')
                local_attrs[:city] = addr_cmpt['short_name']
              end
            end
            formatted_address_cmpts = result.data['formatted_address'].split(',')
            if formatted_address_cmpts.size == 3
              local_attrs[:address1] = formatted_address_cmpts[0]
            elsif formatted_address_cmpts.size == 4
              local_attrs[:address1] = formatted_address_cmpts[1]
            else
              puts "Strange result: #{formatted_address_cmpts.join('|')}"
              local_attrs[:address1] = coreplus_attrs['address']
              local_attrs[:city] = coreplus_attrs['suburb']
              local_attrs[:postcode] = coreplus_attrs['postcode']
            end

            if address2.nil? && result.data['place_id']

            else
              local_attrs[:address2] = address2
            end
            coordinates = result.data.dig 'geometry', 'location'
            local_attrs[:latitude] = coordinates['lat']
            local_attrs[:longitude] = coordinates['lng']
          end
        end

        home_phone = coreplus_attrs['homeNo'].presence
        if home_phone
          local_attrs[:phone] = home_phone
          local_attrs[:phone_formated] = TelephoneNumber.parse(
            home_phone,
            'AU'
          ).international_number
        end

        mobile = coreplus_attrs['mobile'].presence

        if mobile
          local_attrs[:mobile] = mobile
          local_attrs[:mobile_formated] = TelephoneNumber.parse(
            mobile,
            'AU'
          ).international_number
        end

        local_attrs
      end
    end
  end
end
