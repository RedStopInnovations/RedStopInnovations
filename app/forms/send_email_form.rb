class SendEmailForm < BaseForm
  attr_accessor :business, :source, :patient

  attribute :emails, Array
  attribute :email_content, String
  attribute :email_subject, String

  validates :email_content,
            presence: true,
            length: { maximum: 3000 }

  validates :email_subject,
            presence: true,
            length: { maximum: 255 }

  validate do
    # Validate emails
    if !errors.include?(:emails) && !emails.empty?
      unless emails.all? { |email| EmailValidator.valid?(email) }
        errors.add(:emails, 'Some email format has invalid format')
      end
    end
  end
end