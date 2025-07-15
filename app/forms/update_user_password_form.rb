class UpdateUserPasswordForm < BaseForm
  attribute :password, String
  attribute :password_confirmation, String

  validates :password,
            strong_password: true,
            length: {
              minimum: 8,
              maximum: 128, # Same with Devise config
              allow_nil: true,
              allow_blank: true
            },
            allow_blank: true,
            allow_nil: true

  validates_confirmation_of :password
end