# == Schema Information
#
# Table name: admin_users
#
#  id                     :integer          not null, primary key
#  first_name             :string
#  last_name              :string
#  full_name              :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  role                   :string           default(""), not null
#  invitation_token       :string
#  invitation_created_at  :datetime
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_type        :string
#  invited_by_id          :integer
#  invitations_count      :integer          default(0)
#  active                 :boolean          default(TRUE)
#  enabled_2fa            :boolean          default(FALSE)
#  mobile                 :string
#  encrypted_verify_code  :string
#  verify_code_expires_at :datetime
#
# Indexes
#
#  index_admin_users_on_email                 (email) UNIQUE
#  index_admin_users_on_invitation_token      (invitation_token) UNIQUE
#  index_admin_users_on_invitations_count     (invitations_count)
#  index_admin_users_on_invited_by_id         (invited_by_id)
#  index_admin_users_on_reset_password_token  (reset_password_token) UNIQUE
#

class AdminUser < ApplicationRecord
  ROLES = [
    SUPER_ADMIN_ROLE  = 'super_admin',
    RECEPTIONIST_ROLE = 'receptionist',
  ]

  devise :database_authenticatable,
         :rememberable,
         :trackable,
         :validatable,
         :timeoutable

  belongs_to :marketplace

  validates_presence_of :role

  validates :first_name, :last_name,
            presence: true,
            length:{ maximum: 25 }

  before_save do
    self.full_name = [first_name, last_name].compact.join(' ').strip
  end

  scope :receptionist, -> { where(role: RECEPTIONIST_ROLE) }
  scope :super_admin, -> { where(role: SUPER_ADMIN_ROLE) }

  def has_pending_2fa_verification?
    enabled_2fa? && encrypted_verify_code? && verify_code_expires_at? &&
      verify_code_expires_at.future?
  end

  def has_pending_invitation?
    invitation_token? && invitation_accepted_at.nil?
  end

  def is_receptionist?
    role == RECEPTIONIST_ROLE
  end

  def is_super_admin?
    role == SUPER_ADMIN_ROLE
  end

  def timezone
    App::DEFAULT_TIME_ZONE
  end

  def patient_scope
    case role
    when RECEPTIONIST_ROLE, SUPER_ADMIN_ROLE
      Patient.all
    else
      Patient.none
    end
  end

  def timeout_in
    30.minutes
  end
end
