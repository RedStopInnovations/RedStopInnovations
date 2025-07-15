# == Schema Information
#
# Table name: groups
#
#  id          :integer          not null, primary key
#  name        :string
#  description :text
#  category    :string
#  business_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_groups_on_business_id  (business_id)
#

class Group < ApplicationRecord
  has_and_belongs_to_many :practitioners, validate: false
  belongs_to :business

  validates :name,
            presence: true,
            length: { minimum: 3, maximum: 50 }

  validates :description,
            length: { maximum: 500 },
            allow_nil: true,
            allow_blank: true
end
