class SendInternalEmailForm < BaseForm
  attr_accessor :business

  attribute :user_id, Integer
  attribute :subject, String
  attribute :body, String

  validates :user_id,
            presence: true

  validates :body,
            presence: true,
            length: { min: 3, maximum: 500 }

  validates :subject,
            presence: true,
            length: { min: 3, maximum: 255 }

  validate do
    if user_id.present? && !business.users.where(id: user_id).exists?
      errors.add(:user_id, 'does not exist')
    end
  end

  # @TODO: add source and message type?
end
