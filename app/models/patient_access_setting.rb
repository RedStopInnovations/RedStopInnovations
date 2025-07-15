# == Schema Information
#
# Table name: patient_access_settings
#
#  id          :integer          not null, primary key
#  business_id :integer          not null
#  enable      :boolean          default(FALSE)
#
# Indexes
#
#  index_patient_access_settings_on_business_id  (business_id) UNIQUE
#

class PatientAccessSetting < ApplicationRecord
end
