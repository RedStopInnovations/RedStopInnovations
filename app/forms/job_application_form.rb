class JobApplicationForm < BaseForm
  attribute :first_name, String
  attribute :last_name, String
  attribute :email, String
  attribute :password, String
  attribute :password_confirmation, String

  attribute :profession, String
  attribute :mobile, String
  attribute :medicare, String
  attribute :abn, String
  attribute :address1, String
  attribute :city, String
  attribute :state, String
  attribute :postcode, String
  attribute :country, String, default: 'AU'
  attribute :summary, String

  attribute :tos_agreement, Boolean


  validates :first_name, :last_name,
            presence: true,
            length:{ maximum: 25 }

  validates :email, presence: true, email: true

  validates :tos_agreement, acceptance: true
  validates :profession,
            presence: true,
            inclusion: { in: Practitioner::PROFESSIONS }
  validates :mobile,
            presence: true,
            length: { maximum: 50 }
  validates :medicare,
            presence: true,
            length: { maximum: 50 }
  validates :abn,
            presence: true,
            length: { maximum: 50 }
  validates :address1,
            presence: true,
            length: { maximum: 255 }
  validates :city, :state, :postcode, presence: true
  validates :summary,
            presence: true,
            length: { maximum: 5000 }

  validates :password,
            presence: true,
            strong_password: true,
            length: { minimum: 8, maximum: 128 } # Same with Devise config

  validates_confirmation_of :password

  validates :country,
            presence: true

  validate do
    unless errors.has_key?(:email)
      if User.where(email: email).exists?
        errors.add(:email, 'is already taken')
      end
    end
  end
end
