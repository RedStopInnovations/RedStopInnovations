# == Schema Information
#
# Table name: attendance_proof_exports
#
#  id          :bigint           not null, primary key
#  business_id :integer
#  author_id   :integer
#  options     :json
#  description :text
#  status      :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_attendance_proof_exports_on_author_id    (author_id)
#  index_attendance_proof_exports_on_business_id  (business_id)
#
class AttendanceProofExport < ApplicationRecord
  STATUSES = [
    STATUS_PENDING     = 'Pending',
    STATUS_IN_PROGRESS = 'In Progress',
    STATUS_COMPLETED   = 'Completed',
    STATUS_ERROR       = 'Error'
  ]

  has_one_attached :zip_file

  belongs_to :author, class_name: 'User'
  belongs_to :business

  scope :pending, -> { where status: STATUS_PENDING }
  def status_completed?
    status == STATUS_COMPLETED
  end
end
