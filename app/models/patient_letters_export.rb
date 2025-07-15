# == Schema Information
#
# Table name: patient_letters_exports
#
#  id          :bigint           not null, primary key
#  business_id :integer          not null
#  author_id   :integer          not null
#  options     :json
#  description :text
#  status      :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_patient_letters_exports_on_author_id    (author_id)
#  index_patient_letters_exports_on_business_id  (business_id)
#
class PatientLettersExport < ApplicationRecord
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
