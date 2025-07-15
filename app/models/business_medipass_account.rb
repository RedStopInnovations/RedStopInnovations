# == Schema Information
#
# Table name: business_medipass_accounts
#
#  id          :integer          not null, primary key
#  business_id :integer          not null
#  api_key     :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_business_medipass_accounts_on_business_id  (business_id) UNIQUE
#

class BusinessMedipassAccount < ApplicationRecord
  belongs_to :business, inverse_of: :medipass_account

  validates :api_key, presence: true, length: { maximum: 255 }
  validates :business, presence: true
end
