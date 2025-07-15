class SendLetterToPatientForm < BaseForm
  attribute :email_content, String
  attribute :email_subject, String
  attribute :send_format, String

  validates_inclusion_of :send_format, in: %w(email attachment)
  validates_length_of :email_content,
                      maximum: 10000,
                      allow_nil: true,
                      allow_blank: true

  validates :email_subject, presence: true, length: { maximum: 255 }
end
