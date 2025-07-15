RSpec::Matchers.define :has_meta_pagination do
  match do |json_response|
    json_response.has_key?(:meta) &&
      %i(per_page current_page total_pages total_entries).all?{ |key| json_response[:meta].has_key?(key) }
  end

  failure_message do |json_response|
    if json_response.has_key?(:meta)
      missing_keys = %i(per_page current_page total_pages total_entries) - json_response[:meta].keys
      "pagination meta is missing following keys: "\
        "#{missing_keys.join(',')}"
    else
      "JSON response has not 'meta' key"
    end
  end
end

RSpec::Matchers.define :has_pagination_links do
  match do |json_response|
    json_response.has_key?(:links) &&
      %i(first first prev next).all?{ |key| json_response[:links].has_key?(key) }
  end

  failure_message do |json_response|
    if json_response.has_key?(:links)
      missing_keys = %i(first last prev next) - json_response[:links].keys
      "pagination links is missing following keys: "\
        "#{missing_keys.join(',')}"
    else
      "JSON response has not 'links' key"
    end
  end
end
