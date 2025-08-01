class UpdateUserForm < BaseForm
  attr_accessor :user

  attribute :first_name, String
  attribute :last_name, String
  attribute :email, String
  attribute :timezone, String
  attribute :is_practitioner, Boolean
  attribute :active, Boolean
  attribute :role, String
  attribute :employee_number, String

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

  validate do
    unless errors.has_key?(:email)
      if User.where(email: email).where.not(id: user.id).exists?
        errors.add(:email, 'is already taken')
      end
    end
  end

  def self.build_from(user)
    attrs = {
      user: user
    }

    %i(first_name last_name email timezone active is_practitioner role employee_number).
      each do |user_attr|
      attrs[user_attr] = user[user_attr]
    end

    if user.is_practitioner? && user.practitioner
      pract = user.practitioner
      %i(profession medicare phone mobile address1 address2 city state postcode country summary education allow_online_bookings).
        each do |pract_attr|
        attrs[pract_attr] = pract[pract_attr]
      end
    end

    new(attrs)
  end
end
