# == Schema Information
#
# Table name: referral_reject_reasons
#
#  id          :bigint           not null, primary key
#  business_id :integer          not null
#  reason      :string
#  created_at  :datetime
#
# Indexes
#
#  index_referral_reject_reasons_on_business_id  (business_id)
#
class ReferralRejectReason < ApplicationRecord
  self.table_name = 'referral_reject_reasons'

  belongs_to :business
end
