class RegistrationForm < BaseForm
  attribute :business_name, String

  attribute :first_name, String
  attribute :last_name, String
  attribute :email, String

  attribute :country, String

  attribute :timezone, String, default: App::DEFAULT_TIME_ZONE

  attribute :password, String
  attribute :password_confirmation, String

  validates :business_name,
            presence: true,
            length: { minimum: 2, maximum: 150 }

  validates :first_name, :last_name,
            presence: true,
            length: { maximum: 25 }

  validates :email, presence: true, email: true

  validates :country, presence: true

  validates :password,
            presence: true,
            strong_password: true,
            length: { minimum: 8, maximum: 128 } # Same with Devise config

  validates_confirmation_of :password

  validate do
    unless errors.has_key?(:email)
      if User.where(email: email).exists?
        errors.add(:email, "is already taken")
      end
    end
  end
end
