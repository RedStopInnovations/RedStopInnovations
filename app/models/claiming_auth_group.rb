# == Schema Information
#
# Table name: claiming_auth_groups
#
#  id                     :integer          not null, primary key
#  business_id            :integer          not null
#  claiming_auth_group_id :string           not null
#  claiming_minor_id      :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_claiming_auth_groups_on_business_id  (business_id)
#

class ClaimingAuthGroup < ApplicationRecord
  belongs_to :business
  has_many :providers,
           foreign_key: :auth_group_id,
           class_name: 'ClaimingProvider',
           dependent: :delete_all
end
