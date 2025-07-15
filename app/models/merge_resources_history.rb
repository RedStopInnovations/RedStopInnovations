# == Schema Information
#
# Table name: merge_resources_history
#
#  id                  :bigint           not null, primary key
#  author_id           :integer          not null
#  resource_type       :string           not null
#  target_resource_id  :integer          not null
#  merged_resource_ids :string           not null
#  meta                :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_merge_resources_history_on_author_id           (author_id)
#  index_merge_resources_history_on_resource_type       (resource_type)
#  index_merge_resources_history_on_target_resource_id  (target_resource_id)
#
class MergeResourcesHistory < ApplicationRecord
  self.table_name = 'merge_resources_history'

  serialize :merged_resource_ids, type: Array
  serialize :meta, type: Hash
end
