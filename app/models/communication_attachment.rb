# == Schema Information
#
# Table name: communication_attachments
#
#  id                        :integer          not null, primary key
#  communication_template_id :integer          not null
#  attachment_file_name      :string
#  attachment_content_type   :string
#  attachment_file_size      :integer
#  attachment_updated_at     :datetime
#

class CommunicationAttachment < ApplicationRecord
  has_attached_file :attachment
  belongs_to :communication_template

  validates_presence_of :communication_template

  validates_attachment_content_type :attachment,
    content_type: [
      'application/pdf',
      /\Aimage\/.*\Z/,
      'application/vnd.ms-excel',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-office',
      'text/plain'
    ]
  validates_attachment_size :attachment, less_than: 3.megabytes
  validates :attachment, attachment_presence: true
end
