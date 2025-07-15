class ImageDataUrlValidator < ActiveModel::EachValidator
  def validate_each(record, attr, value)
    if value.present?
      parsed_data = Utils::Image.parse_from_data_url(value)
      unless parsed_data
        record.errors.add(attr, options[:message] || 'not a valid format')
      end
    end
  end
end
