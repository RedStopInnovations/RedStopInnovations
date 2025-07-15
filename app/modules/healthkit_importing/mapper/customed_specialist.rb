module HealthkitImporting
    module Mapper
        module CustomedSpecialist
=begin
{
  "Title": "Dr",
  "Forename": "Loretta",
  "Surname": "Weir",
  "Email": "lorwe@example.com",
  "Practice Name": "Kingscliff Medical Centre",
  "Phone": "266743266",
  "Fax": "266743300",
  "Provider No": "210829DW",
  "Address": "40 Marine Parade",
  "Location": "Kingscliff, 2487"
}
=end
            def self.build(healthkit_attrs)
                local_attrs = {
                    title: healthkit_attrs['Title'].presence,
                    first_name: healthkit_attrs['Forename'].to_s.strip.presence,
                    last_name: healthkit_attrs['Surname'].to_s.strip.presence,
                    email: healthkit_attrs['Email'].presence,
                    fax: healthkit_attrs['Fax'].presence,
                    phone: healthkit_attrs['Phone'].presence,
                    country: 'AU',
                    created_at: Time.current,
                    updated_at: Time.current
                }
                full_name = [local_attrs[:first_name], local_attrs[:last_name]].compact.join(' ')
                local_attrs[:full_name] = full_name
                local_attrs[:business_name] = full_name

                notes_lines = []

                if healthkit_attrs['Provider No'].present?
                    notes_lines << "Provider No: #{healthkit_attrs['Provider No'].to_s.strip}"
                end

                if healthkit_attrs['Practice Name'].present?
                    notes_lines << "Practice Name: #{healthkit_attrs['Practice Name'].to_s.strip}"
                end

                if notes_lines.present?
                    local_attrs[:notes] = notes_lines.join("\n")
                end

                # Mapping address
                provided_full_address = [healthkit_attrs['Address'], healthkit_attrs['Location'], 'AU'].join(', ')

                geocoding_results = Geocoder.search(provided_full_address)

                if geocoding_results.blank?
                  log '- No geocode result. Set address as provided'
                  local_attrs[:address1] = provided_full_address
                else

                  geocode_result = geocoding_results.first
                  address1_cmpts = []
                  address2 = nil
                  geocode_result.data['address_components'].each do |addr_cmpt|
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

                  formatted_address_cmpts = geocode_result.data['formatted_address'].split(',')

                  if formatted_address_cmpts.size == 3
                    local_attrs[:address1] = formatted_address_cmpts[0]
                  elsif formatted_address_cmpts.size == 4
                    local_attrs[:address1] = formatted_address_cmpts[1]
                  else
                    puts "Strange result: #{formatted_address_cmpts.join('|')}"

                    local_attrs[:address1] = provided_full_address
                  end

                  if address2.nil? && geocode_result.data['place_id']
                  else
                    local_attrs[:address2] = address2
                  end

                  coordinates = geocode_result.data.dig 'geometry', 'location'
                  local_attrs[:latitude] = coordinates['lat']
                  local_attrs[:longitude] = coordinates['lng']
                end

                local_attrs
            end
        end
    end
end
