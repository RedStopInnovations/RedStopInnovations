# == Schema Information
#
# Table name: billable_items_contacts
#
#  id               :integer          not null, primary key
#  billable_item_id :integer
#  contact_id       :integer
#  price            :decimal(10, 2)   default(0.0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_billable_items_contacts_on_billable_item_id  (billable_item_id)
#  index_billable_items_contacts_on_contact_id        (contact_id)
#

class BillableItemsContacts < ApplicationRecord

  belongs_to :contact, -> { with_deleted }
  belongs_to :item, class_name: 'BillableItem', inverse_of: :pricing_contacts, foreign_key: 'billable_item_id'

  validates_presence_of :contact_id, :price
  validates :price, presence: true,
                    numericality: { greater_than: 0 }
  validates :contact_id, uniqueness: { scope: :billable_item_id }
end
