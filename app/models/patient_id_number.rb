# == Schema Information
#
# Table name: patient_id_numbers
#
#  id         :integer          not null, primary key
#  patient_id :integer
#  contact_id :integer
#  id_number  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_patient_id_numbers_on_contact_id  (contact_id)
#  index_patient_id_numbers_on_patient_id  (patient_id)
#

class PatientIdNumber < ApplicationRecord
  belongs_to :patient, -> { with_deleted }, touch: true
  belongs_to :contact, -> { with_deleted }

  validates_presence_of :id_number, :contact_id
end
