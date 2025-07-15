# == Schema Information
#
# Table name: claiming_providers
#
#  id              :integer          not null, primary key
#  auth_group_id   :integer          not null
#  name            :string           not null
#  provider_number :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class ClaimingProvider < ApplicationRecord
end
