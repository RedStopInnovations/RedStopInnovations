# == Schema Information
#
# Table name: business_stripe_accounts
#
#  id              :integer          not null, primary key
#  business_id     :integer          not null
#  account_id      :string           not null
#  access_token    :string
#  refresh_token   :string
#  publishable_key :string
#  connected_at    :datetime
#
# Indexes
#
#  index_business_stripe_accounts_on_business_id  (business_id) UNIQUE
#

class BusinessStripeAccount < ApplicationRecord
end
