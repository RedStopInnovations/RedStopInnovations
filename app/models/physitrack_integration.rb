# == Schema Information
#
# Table name: physitrack_integrations
#
#  id          :integer          not null, primary key
#  business_id :integer          not null
#  enabled     :boolean          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_physitrack_integrations_on_business_id  (business_id) UNIQUE
#

class PhysitrackIntegration < ApplicationRecord
  belongs_to :business
end
