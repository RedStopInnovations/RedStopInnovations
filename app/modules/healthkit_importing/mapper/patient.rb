module HealthkitImporting
  module Mapper
    module Patient
=begin
  Healthkit field                               Local column
  ----------------------------------------------------------------------
  "id":               "248526",                  N/A
  "title":            "Mrs",                     N/A
  "forename":         "Lyn",                     first_name
  "middle":           "",                        middle_name
  "surname":          "Murray",                  last_name
  "preferred":        "",                        N/A
  "dob":              "1952-10-24",              dob
  "gender":           "male"                     gender
  "alertnotes":       "",                        important_notification
  "email":            "lyn.murray1@gmail.com",   email
  "terminology":      "Patient",                 N/A
  "notes":            "",                        general_info
  "reviewdate":       "",                        N/A
  "reviewnotes":      "",                        ?
  "referralsource":   "",                        ?
  "referraldate":     "",                        ?
  "referralcomments": "",                        ?
  "status":           "current"
                      "discharged"               archived_at
                      "deceased"                 archived_at
                      "archived"                 archived_at
                      "blocked"                  archived_at
                      "deleted"                  deleted_at


=end
      # Notes:
      # - Country fixed to AU
      def self.build(healthkit_attrs)
        local_attrs = {
          first_name: healthkit_attrs['forename'].to_s.strip.presence,
          last_name: healthkit_attrs['surname'].to_s.strip.presence,
          email: healthkit_attrs['email'].presence,
          important_notification: healthkit_attrs['alertnotes'].presence,
          created_at: Time.current,
          updated_at: Time.current
        }

        local_attrs[:full_name] = [
          local_attrs[:first_name],
          local_attrs[:last_name]
        ].compact.join(' ')

        local_attrs[:gender] = {
          'female' => 'Female',
          'male'  => 'Male'
        }[healthkit_attrs['gender']]

        if healthkit_attrs['dob'].present?
          local_attrs[:dob] = Date.parse(healthkit_attrs['dob']) rescue nil
        end

        heatlkit_status = healthkit_attrs['status'].presence
        case healthkit_attrs['status']
        when 'discharged', 'deceased', 'archived', 'blocked'
          local_attrs[:archived_at] = Time.current
        when 'deleted'
          local_attrs[:archived_at] = Time.current
          local_attrs[:deleted_at] = Time.current
        end

        if local_attrs[:archived_at] || local_attrs[:deleted_at]
          local_attrs[:reminder_enable] = false
        end

        general_info_lines = []

        if healthkit_attrs['notes'].present?
          general_info_lines << "Notes: #{healthkit_attrs['notes']}"
        end

        if healthkit_attrs['reviewdate'].present?
          general_info_lines << "Review date: #{healthkit_attrs['reviewdate']}"
        end

        if healthkit_attrs['reviewnotes'].present?
          general_info_lines << "Review notes: #{healthkit_attrs['reviewnotes']}"
        end

        if healthkit_attrs['referralsource'].present?
          general_info_lines << "Referral source: #{healthkit_attrs['referralsource']}"
        end

        if healthkit_attrs['referraldate'].present?
          general_info_lines << "Referral date: #{healthkit_attrs['referraldate']}"
        end

        if healthkit_attrs['referralcomments'].present?
          general_info_lines << "Referral comments: #{healthkit_attrs['referralcomments']}"
        end

        if general_info_lines.present?
          local_attrs[:general_info] = general_info_lines.join("\n")
        end

        local_attrs
      end
    end
  end
end
