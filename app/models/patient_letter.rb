# == Schema Information
#
# Table name: patient_letters
#
#  id                 :integer          not null, primary key
#  patient_id         :integer          not null
#  letter_template_id :integer
#  business_id        :integer          not null
#  author_id          :integer
#  description        :string
#  content            :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_patient_letters_on_business_id         (business_id)
#  index_patient_letters_on_letter_template_id  (letter_template_id)
#  index_patient_letters_on_patient_id          (patient_id)
#

class PatientLetter < ApplicationRecord
  belongs_to :business
  belongs_to :patient, -> { with_deleted }, inverse_of: :letters
  belongs_to :letter_template, optional: true
  belongs_to :author, class_name: 'Practitioner', optional: true

  validates_presence_of :business, :patient
  validates :description, presence: true, length: { maximum: 255 }
  validates :content, presence: true, length: { maximum: 2000000 }
end
