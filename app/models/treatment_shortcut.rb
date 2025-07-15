# == Schema Information
#
# Table name: treatment_shortcuts
#
#  id          :integer          not null, primary key
#  content     :text             not null
#  business_id :integer
#
# Indexes
#
#  index_treatment_shortcuts_on_business_id  (business_id)
#

class TreatmentShortcut < ApplicationRecord
  belongs_to :business

  validates :content, presence: true, length: { maximum: 1000 },
                      uniqueness: { scope: :business }
end
