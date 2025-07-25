class SmsSettings < ApplicationRecord
  self.table_name = 'sms_settings'

  belongs_to :business
end
