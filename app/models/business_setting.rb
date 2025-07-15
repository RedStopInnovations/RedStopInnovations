# == Schema Information
#
# Table name: business_settings
#
#  id                 :integer          not null, primary key
#  storage_url        :string
#  business_id        :integer
#  sms_sender_id      :string
#  google_tag_manager :json
#
# Indexes
#
#  index_business_settings_on_business_id  (business_id)
#

class BusinessSetting < ApplicationRecord
  belongs_to :business

  validates_format_of :storage_url,
                      with: URI.regexp,
                      allow_blank: true,
                      allow_nil: true
end
