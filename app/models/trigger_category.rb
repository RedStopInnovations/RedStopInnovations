# == Schema Information
#
# Table name: trigger_categories
#
#  id          :integer          not null, primary key
#  business_id :integer          not null
#  name        :string
#  words_count :integer          default(0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_trigger_categories_on_business_id  (business_id)
#

class TriggerCategory < ApplicationRecord
  belongs_to :business
  has_one :trigger_report, as: :trigger_source, dependent: :delete
  has_many :words,
           class_name: 'TriggerWord',
           foreign_key: :category_id,
           dependent: :destroy

  accepts_nested_attributes_for :words, allow_destroy: true

  validates_presence_of :name,
                        length: { maximum: 150 }
end
