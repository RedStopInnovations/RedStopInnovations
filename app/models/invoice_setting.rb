# == Schema Information
#
# Table name: invoice_settings
#
#  id                      :integer          not null, primary key
#  business_id             :integer          not null
#  starting_invoice_number :integer          default(1), not null
#  updated_at              :datetime
#  messages                :text
#  enable_services         :boolean          default(FALSE)
#  enable_diagnosis        :boolean          default(FALSE)
#  outstanding_reminder    :json
#
# Indexes
#
#  index_invoice_settings_on_business_id  (business_id)
#

class InvoiceSetting < ApplicationRecord
  validates_presence_of :business_id
end
