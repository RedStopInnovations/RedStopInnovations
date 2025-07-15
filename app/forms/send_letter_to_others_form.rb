class SendLetterToOthersForm < BaseForm
  attr_accessor :business

  attribute :contact_ids, Array
  attribute :emails, Array
  attribute :email_content, String
  attribute :email_subject, String
  attribute :send_format, String

  validates_inclusion_of :send_format, in: %w(email attachment)
  validates_length_of :email_content,
                      maximum: 10000,
                      allow_nil: true,
                      allow_blank: true

  validates :email_subject, presence: true, length: { maximum: 255 }

  validate do
    # Validate existing for contact ids
    if !errors.include?(:contact_ids) && !contact_ids.empty?
      sanitized_contact_ids = contact_ids.uniq
      if business.contacts.where(id: sanitized_contact_ids).count != sanitized_contact_ids.size
        errors.add(:contact_ids, 'containts invalid contact')
      end
    end

    # Validate emails
    if !errors.include?(:emails) && !emails.empty?
      unless emails.all? { |email| EmailValidator.valid?(email) }
        errors.add(:emails, 'Some email is not valid')
      end
    end

    # Validate at least 1 recipient
    if !errors.include?(:contact_ids) && !errors.include?(:emails)
      if contact_ids.empty? && emails.empty?
        errors.add(:base, 'No recipient specified')
      end
    end
  end
end
