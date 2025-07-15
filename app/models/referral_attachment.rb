# == Schema Information
#
# Table name: referral_attachments
#
#  id                      :integer          not null, primary key
#  referral_id             :integer
#  attachment_file_name    :string
#  attachment_content_type :string
#  attachment_file_size    :integer
#  attachment_updated_at   :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_referral_attachments_on_referral_id  (referral_id)
#

class ReferralAttachment < ApplicationRecord
  belongs_to :referral
  has_attached_file :attachment

  validates_attachment_content_type :attachment,
    content_type: [
      'application/pdf',
      /\Aimage\/.*\Z/
    ]
  validates_attachment_size :attachment, less_than: 5.megabytes
end
