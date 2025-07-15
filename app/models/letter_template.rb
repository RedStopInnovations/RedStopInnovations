# == Schema Information
#
# Table name: letter_templates
#
#  id            :integer          not null, primary key
#  business_id   :integer          not null
#  name          :string           not null
#  content       :text
#  email_subject :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_letter_templates_on_business_id  (business_id)
#

class LetterTemplate < ApplicationRecord
  belongs_to :business
  has_many :patient_letters, dependent: :nullify

  validates_presence_of :business

  validates :name,
            presence: true,
            length: { maximum: 100 }

  validates :content,
            presence: true,
            length: { maximum: 2000000 }

  validates :email_subject,
            length: { maximum: 255 }
end
