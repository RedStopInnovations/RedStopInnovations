# == Schema Information
#
# Table name: calendar_appearance_settings
#
#  id                       :bigint           not null, primary key
#  business_id              :integer          not null
#  availability_type_colors :text
#  appointment_type_colors  :text
#  is_show_tasks            :boolean          default(FALSE)
#
# Indexes
#
#  index_calendar_appearance_settings_on_business_id  (business_id)
#
class CalendarAppearanceSetting < ApplicationRecord
  belongs_to :business
  serialize :appointment_type_colors, type: Array
  serialize :availability_type_colors, type: Array
end
