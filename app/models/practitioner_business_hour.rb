# == Schema Information
#
# Table name: practitioner_business_hours
#
#  id              :bigint           not null, primary key
#  practitioner_id :integer          not null
#  day_of_week     :integer          not null
#  active          :boolean          default(TRUE)
#  availability    :json
#
# Indexes
#
#  index_practitioner_business_hours_on_practitioner_id  (practitioner_id)
#
class PractitionerBusinessHour < ApplicationRecord
  self.table_name = 'practitioner_business_hours'

  belongs_to :practitioner
end
