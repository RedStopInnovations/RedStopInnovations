class SendAvailabilityBulkSmsForm < BaseForm
  attribute :communication_category, String
  attribute :content, String
  attribute :send_option, String

  validates :send_option, inclusion: {in: ['FORCE_ALL', 'SKIP_REMINDER_DISABLED'] }
  validates :communication_category,
            inclusion: { in: Communication::CATEGORIES }

  validates :content, presence: true, length: { maximum: 500 }
end