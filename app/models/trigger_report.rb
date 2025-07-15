# == Schema Information
#
# Table name: trigger_reports
#
#  id                  :integer          not null, primary key
#  trigger_source_id   :string           not null
#  trigger_source_type :integer          not null
#  mentions_count      :integer          default(0), not null
#  patients_count      :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  idx_trigger_reports_source_id_type  (trigger_source_id,trigger_source_type)
#

class TriggerReport < ApplicationRecord
  belongs_to :trigger_source, polymorphic: true
end
