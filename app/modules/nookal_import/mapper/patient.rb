module NookalImport
  module Mapper
    module Patient

=begin
  Nookal field           Sample value               Local column
  ----------------------------------------------------------------------
  "ClientID":               248526,                     N/A
  "location":               "All Locations"             N/A
  "Title":                  Mr, Mrs, Miss               N/A
  "FirstName":              Ashton                      first_name
  "LastName":               Palmer                      last_name
  "Gender":                 M, F                        gender
  "DOB":                    2002-08-20                  dob
  "Notes":                  "",                         general_info
  "DiaryAlertNotes":        "",
  "Addr1":                  "",                         address1
  "Addr2":                  "",                         address2
  "Addr3":                  "",
  "City":                   "",                         city
  "State":                  "",                         state
  "Postcode":               "",                         postcode
  "Country":                "",                         country
  "Home":                   "current"                   phone
  "Work":                   "current"                   phone
  "Mobile":                 "current"                   mobile
  "Fax":                    "current"
  "Email":                  "current"
  "onlineQuickCode":        "current"
  "category":               "current"
  "businessUnit":           "current"
  "allergies":              "current"
  "PrivateHealthNo":        "current"
  "PrivateHealthCompany":   "current"
  "PrivateHealthPhNo":      "current"
  "publicHealthData":       "current"
  "consent":                "current"
  "deceased":               "current"
  "Active":                 "current"
  "RegistrationDate":       "current"
  "SMS Reminders":          "current"
  "Email Reminders":        "current"
  "SMS Marketing":          "current"
  "Email Marketing":        "current"
  "Extras":                 "current"

=end
      # Notes:
      #   - Country is fixed to AU
      def self.build(nookal_attrs)
        local_attrs = {
          first_name: nookal_attrs['FirstName'].to_s.strip.presence,
          last_name: nookal_attrs['LastName'].to_s.strip.presence,
          email: nookal_attrs['Email'].presence,
          created_at: Time.current,
          updated_at: Time.current
        }

        local_attrs[:full_name] = [
          local_attrs[:first_name],
          local_attrs[:last_name]
        ].compact.join(' ')

        local_attrs[:gender] = {
          'F' => 'Female',
          'M'  => 'Male'
        }[nookal_attrs['Gender']]

        if nookal_attrs['Mobile'].present?
          local_attrs[:mobile] = nookal_attrs['Mobile']
          tele_number = TelephoneNumber.parse(
            nookal_attrs['Mobile'],
            'AU'
          )

          if tele_number.valid?
            local_attrs[:mobile_formated] = tele_number.international_number
          end
        end

        if nookal_attrs['Home'].present?
          local_attrs[:phone] = nookal_attrs['Home']
          tele_number = TelephoneNumber.parse(
            nookal_attrs['Home'],
            'AU'
          )

          if tele_number.valid?
            local_attrs[:phone_formated] = tele_number.international_number
          end
        end

        if nookal_attrs['DOB'].present?
          local_attrs[:dob] = Date.parse(nookal_attrs['DOB']) rescue nil
        end

        # Address
        local_attrs[:address1] = nookal_attrs['Addr1'].presence
        local_attrs[:address2] = nookal_attrs['Addr2'].presence
        local_attrs[:city] = nookal_attrs['City'].presence
        local_attrs[:state] = nookal_attrs['State'].presence
        local_attrs[:postcode] = nookal_attrs['Postcode'].presence
        local_attrs[:country] = 'AU' # Note: fixed to Australia

        local_attrs[:general_info] = nookal_attrs['Notes'].presence

        if local_attrs['deceased'] == '1'
          local_attrs[:archived_at] = Time.current
        end

        if nookal_attrs['SMS Reminders'] == '1' || nookal_attrs['Email Reminders'] == '1'
          local_attrs[:reminder_enable] = true
        end

        if local_attrs[:archived_at] || local_attrs[:deleted_at]
          local_attrs[:reminder_enable] = false
        end

        # NOTE: not sure how to import this
        if nookal_attrs['publicHealthData'].present?
          begin
            public_health_data = JSON.parse(nookal_attrs['publicHealthData'])

            # Medicare details
            medicare_info = public_health_data['MEDICARE']
            if medicare_info
              # Example: {"Name"=>"Medicare", "Reference"=>"2181938409-2", "ExpiryDate"=>nil, "Verified"=>1}
            end

            # dva_details
            dva_info = public_health_data['DVA']
            if dva_info
              # Example: {"Name"=>"DVA", "Reference"=>nil, "ExpiryDate"=>nil, "Type"=>nil, "Disability"=>nil, "Verified"=>0}
            end
          rescue JSON::ParserError => e
            # do nothing
          end
        end

        local_attrs
      end
    end
  end
end
