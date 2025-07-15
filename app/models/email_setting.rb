# == Schema Information
#
# Table name: email_settings
#
#  id           :integer          not null, primary key
#  business_id  :integer
#  status       :boolean          default(TRUE)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  setting_type :string
#
# Indexes
#
#  index_email_settings_on_business_id_and_setting_type  (business_id,setting_type) UNIQUE
#

class EmailSetting < ApplicationRecord
  TYPE = ["new", "cancel"] # FIXME: shit names. We dont have appointment notification only

  NEW_APPOINTMENT = 'new'
  CANCEL_APPOINTMENT = 'cancel'

  belongs_to :business

  validates_presence_of :setting_type

  default_scope {where("setting_type is not null")}

  def checkbox_label
  case setting_type.to_sym
    when :new
      "new appointment created"
    when :cancel
      "appointment is cancelled"
    else
      ""
    end
  end

end
