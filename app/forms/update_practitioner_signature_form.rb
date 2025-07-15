class UpdatePractitionerSignatureForm < BaseForm
  attribute :signature_image_data_url, String
  attribute :signature_image_file, ActionDispatch::Http::UploadedFile

  validates :signature_image_file,
            file_size: { less_than_or_equal_to: 100.kilobytes },
            file_content_type: { allow: ['image/jpeg', 'image/png'] },
            allow_nil: true

  validate do
    if signature_image_data_url.nil? && signature_image_file.nil?
      errors.add(:base, 'No image source provided')
    end
  end

  validate do
    if signature_image_data_url.present?
      if Utils::Image.parse_from_data_url(signature_image_data_url).nil?
        errors.add(:signature_image_data_url, 'is not a valid image data url')
      end
    end
  end
end