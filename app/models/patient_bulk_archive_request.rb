# == Schema Information
#
# Table name: patient_bulk_archive_requests
#
#  id                      :bigint           not null, primary key
#  business_id             :integer          not null
#  author_id               :integer          not null
#  description             :text
#  filters                 :json
#  archived_patients_count :integer
#  status                  :string           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  archived_patient_ids    :text
#
# Indexes
#
#  index_patient_bulk_archive_requests_on_business_id  (business_id)
#
class PatientBulkArchiveRequest < ApplicationRecord
  self.table_name = 'patient_bulk_archive_requests'

  STATUSES = [
    STATUS_PENDING     = 'Pending',
    STATUS_IN_PROGRESS = 'In Progress',
    STATUS_COMPLETED   = 'Completed',
    STATUS_ERROR       = 'Error'
  ]

  belongs_to :author, class_name: 'User'
  belongs_to :business

  scope :pending, -> { where status: STATUS_PENDING }
  scope :not_finished, -> { where status: [STATUS_PENDING, STATUS_IN_PROGRESS] }

  def status_completed?
    status == STATUS_COMPLETED
  end
end
