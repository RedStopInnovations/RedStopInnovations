# == Schema Information
#
# Table name: referral_enquiry_qualifications
#
#  id              :integer          not null, primary key
#  name            :string
#  email           :string
#  phone           :string
#  status          :string
#  token           :string
#  expires_at      :datetime
#  practitioner_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_referral_enquiry_qualifications_on_practitioner_id  (practitioner_id)
#

class ReferralEnquiryQualification < ApplicationRecord
  STATUS_APPROVED = "Approved"
  STATUS_DENIED = "Denied"

  before_save :set_token

  belongs_to :practitioner

  validates_presence_of :name, :email, :phone, :practitioner
  validates :email,
            email: true,
            length: { maximum: 255 },
            allow_nil: true,
            allow_blank: true
  
  def expired?
    DateTime.now > expires_at
  end

  def approved?
    self.status == STATUS_APPROVED
  end

  def denied?
    self.status == STATUS_DENIED
  end

  private
  def set_token
    self.token = SecureRandom.uuid if self.token.nil?
  end
end
