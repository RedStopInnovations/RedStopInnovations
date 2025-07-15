module HealthkitImporting
  module Mapper
    module Contact
=begin
  Healthkit field                               Local column
  ----------------------------------------------------------------------
  "id":               "248526",                 N/A
  "name":             "Feros Care",             business_name
  "registation":      "",                       notes
  "website":          "",                       notes
  "email":            "nlee@care.org.au",       email
  "comments":         "",                       notes
=end
      # Notes:
      def self.build(healthkit_attrs)
        local_attrs = {
          business_name: healthkit_attrs['name'].to_s.strip.presence,
          email: healthkit_attrs['email'].presence,
          created_at: Time.current,
          updated_at: Time.current
        }

        notes_lines = []

        if healthkit_attrs['comments'].present?
          notes_lines << "#{healthkit_attrs['comments']}"
        end

        if healthkit_attrs['website'].present?
          notes_lines << "Website: #{healthkit_attrs['website']}"
        end

        if notes_lines.present?
          local_attrs[:notes] = notes_lines.join("\n")
        end

        local_attrs
      end
    end
  end
end
