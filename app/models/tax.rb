# == Schema Information
#
# Table name: taxes
#
#  id            :integer          not null, primary key
#  name          :string
#  rate          :float
#  business_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  myob_tax_id   :string
#  xero_tax_type :string
#
# Indexes
#
#  index_taxes_on_business_id  (business_id)
#

class Tax < ApplicationRecord
  belongs_to :business
  has_many :billable_items

  validates :name, :rate, presence: true
  validates_length_of :name, maximum: 250

  validates :rate, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }
end
