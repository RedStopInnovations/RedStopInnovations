class CreateUserForm < BaseForm
  attribute :first_name, String
  attribute :last_name, String
  attribute :email, String
  attribute :avatar_data_url, String
  attribute :timezone, String
  attribute :is_practitioner, Boolean
  attribute :role, String
  attribute :employee_number, String

  attribute :password, String
  attribute :password_confirmation, String
  attribute :send_invitation_email, Boolean, default: true

  # Practitioner info
  attribute :profession, String
  attribute :medicare, String
  attribute :phone, String
  attribute :mobile, String
  attribute :website, String
  attribute :address1, String
  attribute :address2, String
  attribute :city, String
  attribute :state, String
  attribute :postcode, String
  attribute :country, String
  attribute :summary, String
  attribute :education, String
  attribute :allow_online_bookings, Boolean

  validates :first_name, :last_name,
            presence: true,
            length:{ maximum: 25 }
  validates :email, presence: true, email: true
  validates :role,
            presence: true,
            inclusion: { in: User::ROLES }

  validates :employee_number,
            length: { maximum: 25 },
            allow_nil: true,
            allow_blank: true

  validates_presence_of :address1, :city, :state, :postcode, :country,
            if: :is_practitioner?

  validates :profession,
            presence: true,
            inclusion: { in: Practitioner::PROFESSIONS },
            if: :is_practitioner?

  validates :mobile, :phone,
            length: { maximum: 50 },
            allow_nil: true,
            allow_blank: true,
            if: :is_practitioner?
  validates :medicare,
            length: { maximum: 50 },
            allow_nil: true,
            allow_blank: true,
            if: :is_practitioner?

  validates :summary, length: { maximum: 5000 },
            if: :is_practitioner?
  validates :education, length: { maximum: 250 },
            allow_nil: true,
            allow_blank: true,
            if: :is_practitioner?

  validates :password,
            presence: true,
            strong_password: true,
            length: {
              minimum: 8,
              maximum: 128,
              allow_blank: true,
              allow_nil: true
            }, # Same with Devise config
            unless: :send_invitation_email

  validates :avatar_data_url,
            image_data_url: true,
            allow_nil: true,
            allow_blank: true

  validates_confirmation_of :password,
            unless: :send_invitation_email

  validate do
    unless errors.has_key?(:email)
      if User.where(email: email).exists?
        errors.add(:email, 'is already taken')
      end
    end
  end
end
