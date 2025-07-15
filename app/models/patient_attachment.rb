# == Schema Information
#
# Table name: patient_attachments
#
#  id                      :integer          not null, primary key
#  patient_id              :integer          not null
#  attachment_file_name    :string
#  attachment_content_type :string
#  attachment_file_size    :integer
#  attachment_updated_at   :datetime
#  description             :text
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  patient_case_id         :integer
#
# Indexes
#
#  index_patient_attachments_on_patient_case_id  (patient_case_id)
#  index_patient_attachments_on_patient_id       (patient_id)
#

class PatientAttachment < ApplicationRecord
  has_attached_file :attachment

  auto_strip_attributes :description, squish: true

  belongs_to :patient, -> { with_deleted }, inverse_of: :attachments
  belongs_to :patient_case

  validates_presence_of :patient, :attachment
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
  validates_attachment_size :attachment, less_than: 20.megabytes
  validates_length_of :description, maximum: 1000
end
