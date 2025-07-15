# == Schema Information
#
# Table name: hicaps_items
#
#  id          :integer          not null, primary key
#  item_number :string           not null
#  description :string           not null
#  abbr        :string
#  category    :string
#
# Indexes
#
#  index_hicaps_items_on_item_number  (item_number)
#

class HicapsItem < ApplicationRecord
  validates_presence_of :item_number, :description
end
