# == Schema Information
#
# Table name: versions
#
#  id             :bigint           not null, primary key
#  item_type      :string           not null
#  item_id        :bigint           not null
#  event          :string           not null
#  whodunnit      :string
#  object         :json
#  object_changes :json
#  created_at     :datetime
#  ip             :string
#  user_agent     :string
#
# Indexes
#
#  index_versions_on_item_type_and_item_id  (item_type,item_id)
#
class PaperTrailVersion < ApplicationRecord
  include PaperTrail::VersionConcern

  self.table_name = 'versions'

  belongs_to :author, class_name: 'User', foreign_key: :whodunnit
end
