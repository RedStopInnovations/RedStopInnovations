class UpdatePractitionerDocumentForm < BaseForm
  attribute :type, String
  attribute :file, ActionDispatch::Http::UploadedFile
  attribute :expiry_date, String

  validates :file,
            file_size: { less_than_or_equal_to: 5.megabytes },
            file_content_type: {
              allow: ['image/jpeg', 'image/png', 'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
              message: 'images, documents and PDF only'
            },
            allow_blank: true,
            allow_nil: true

  validates :type,
            presence: true,
            inclusion: { in: PractitionerDocument::TYPES }

  validates_date :expiry_date,
            allow_blank: true,
            allow_nil: true
end