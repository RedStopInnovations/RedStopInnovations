# == Schema Information
#
# Table name: patient_accesses
#
#  id         :integer          not null, primary key
#  patient_id :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_patient_accesses_on_patient_id  (patient_id)
#  index_patient_accesses_on_user_id     (user_id)
#

class PatientAccess < ApplicationRecord
  belongs_to :patient, -> { with_deleted }
  belongs_to :user
end
