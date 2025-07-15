# == Schema Information
#
# Table name: business_mailchimp_settings
#
#  id          :integer          not null, primary key
#  business_id :integer          not null
#  list_name   :string
#  api_key     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class BusinessMailchimpSetting < ApplicationRecord

  belongs_to :business

  validates_length_of :list_name,
                      maximum: 250,
                      allow_nil: true,
                      allow_blank: true

  validates_length_of :api_key,
                      maximum: 250,
                      allow_nil: true,
                      allow_blank: true

  validate :check_valid_api_key_and_list_name

  def check_valid_api_key_and_list_name
    begin
      if self.api_key.present?
        mailchimp = Mailchimp::API.new(self.api_key) if self.api_key.present?
        lists = mailchimp.lists.list({list_name: self.list_name})
        if self.list_name.present? && lists['data'].select {|list| list['name'] == self.list_name}.blank?
          errors.add(:list_name, 'not same as it is named in MailChimp')
        end
      end
    rescue Mailchimp::ListDoesNotExistError => e
      errors.add(:list_name, 'not same as it is named in MailChimp')
    rescue Exception => e
      errors.add(:api_key, 'is invalid')
    end
  end

  def settings_completed?
    api_key? && list_name?
  end
end
