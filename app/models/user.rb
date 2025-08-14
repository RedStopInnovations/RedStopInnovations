# == Schema Information
#
# Table name: users
#
#  id                                     :integer          not null, primary key
#  email                                  :string           default(""), not null
#  encrypted_password                     :string           default(""), not null
#  reset_password_token                   :string
#  reset_password_sent_at                 :datetime
#  remember_created_at                    :datetime
#  sign_in_count                          :integer          default(0), not null
#  current_sign_in_at                     :datetime
#  last_sign_in_at                        :datetime
#  current_sign_in_ip                     :string
#  last_sign_in_ip                        :string
#  created_at                             :datetime         not null
#  updated_at                             :datetime         not null
#  business_id                            :integer
#  timezone                               :string           default("Australia/Brisbane"), not null
#  invitation_token                       :string
#  invitation_created_at                  :datetime
#  invitation_sent_at                     :datetime
#  invitation_accepted_at                 :datetime
#  invitation_limit                       :integer
#  invited_by_type                        :string
#  invited_by_id                          :integer
#  invitations_count                      :integer          default(0)
#  role                                   :string           default(""), not null
#  first_name                             :string
#  last_name                              :string
#  full_name                              :string
#  is_practitioner                        :boolean          default(TRUE)
#  avatar_file_name                       :string
#  avatar_content_type                    :string
#  avatar_file_size                       :integer
#  avatar_updated_at                      :datetime
#  active                                 :boolean          default(TRUE)
#  google_authenticator_secret            :string
#  enable_google_authenticator            :boolean          default(FALSE)
#  employee_number                        :string
#  google_authenticator_secret_created_at :datetime
#
# Indexes
#
#  index_users_on_active                  (active)
#  index_users_on_business_id             (business_id)
#  index_users_on_business_id_and_active  (business_id,active)
#  index_users_on_email                   (email) UNIQUE
#  index_users_on_invitation_token        (invitation_token) UNIQUE
#  index_users_on_invitations_count       (invitations_count)
#  index_users_on_invited_by_id           (invited_by_id)
#  index_users_on_is_practitioner         (is_practitioner)
#  index_users_on_reset_password_token    (reset_password_token) UNIQUE
#

class User < ApplicationRecord
  include RansackAuthorization::User
  acts_as_google_authenticated issuer: 'Tracksy',
                               google_secret_column: :google_authenticator_secret,
                               lookup_token: :id

  ROLES = [
    ADMINISTRATOR_ROLE = 'administrator',
    SUPERVISOR_ROLE    = 'supervisor',
    RESTRICTED_SUPERVISOR_ROLE = 'restricted supervisor',
    PRACTITIONER_ROLE  = 'practitioner',
    RESTRICTED_PRACTITIONER_ROLE  = 'restricted practitioner',
    RECEPTIONIST_ROLE  = 'receptionist',
    VIRTUAL_RECEPTIONIST_ROLE  = 'virtual receptionist',
  ]

  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :invitable

  has_attached_file :avatar,
                    use_timestamp: true,
                    styles: {
                      medium: "300x300>",
                      thumb: "100x100#"
                    },
                    convert_options: {
                      thumb: "-quality 75 -strip",
                      medium: "-quality 75 -strip"
                    },
                    s3_headers: {
                      'Cache-Control' => 'max-age=2592000',
                      'Expires' => 30.days.from_now.httpdate
                    },
                    default_url: -> (attachment) {
                      ActionController::Base.helpers.asset_path(
                        'default-avatar.png'
                      )
                    }

  has_paper_trail(
    only: [
      :first_name, :last_name, :email, :role, :is_practitioner, :active
    ],
    on: [:create, :update, :destroy],
    versions: {
      class_name: 'PaperTrailVersion'
    }
  )

  belongs_to :business
  has_one :practitioner, inverse_of: :user
  has_one :google_calendar_sync_setting, class_name: 'UserGoogleCalendarSyncSetting'
  has_many :preferences, foreign_key: :user_id, class_name: 'UserPreference'
  accepts_nested_attributes_for :practitioner

  validates_presence_of :business

  validates :first_name, :last_name,
            presence: true,
            length:{ maximum: 25 }
  validates :role,
            presence: true,
            inclusion: { in: ROLES }
  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\z/

  validates :password,
            strong_password: true,
            on: [:create, :update]

  validates :employee_number,
            length: { maximum: 25 },
            allow_nil: true,
            allow_blank: true

  scope :role_administrator, -> { where(role: ADMINISTRATOR_ROLE) }
  scope :role_supervisor, -> { where(role: SUPERVISOR_ROLE) }
  scope :role_practitioner, -> { where(role: PRACTITIONER_ROLE) }
  scope :not_role_administrator, -> { where.not(role: ADMINISTRATOR_ROLE) }
  scope :active, -> { where(active: true) }
  scope :practitioner_user, -> { where(is_practitioner: true) }
  scope :not_role_receptionist, -> { where.not(role: RECEPTIONIST_ROLE) }

  def role_administrator?
    role == ADMINISTRATOR_ROLE
  end

  def role_supervisor?
    role == SUPERVISOR_ROLE
  end

  def role_restricted_supervisor?
    role == RESTRICTED_SUPERVISOR_ROLE
  end

  def role_practitioner?
    role == PRACTITIONER_ROLE
  end

  def role_restricted_practitioner?
    role == RESTRICTED_PRACTITIONER_ROLE
  end

  def role_receptionist?
    role == RECEPTIONIST_ROLE
  end

  def role_virtual_receptionist?
    role == VIRTUAL_RECEPTIONIST_ROLE
  end

  def active_for_authentication?
    super && active? && !business.suspended?
  end

  def inactive?
    !active?
  end

  def self.to_csv
    attributes = %w{id email first_name last_name}

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |user|
        csv << user.attributes.values_at(*attributes)
      end
    end
  end
end
