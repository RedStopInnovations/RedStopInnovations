class SendAttachmentToContactsForm < BaseForm
  attr_accessor :business

  attribute :contact_ids, Array
  attribute :emails, Array
  attribute :message, String

  validates_presence_of :message
  validates_length_of :message, maximum: 1000

  validate do
    # Validate existing for contact ids
    if !errors.include?(:contact_ids)
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
