# == Schema Information
#
# Table name: billable_items
#
#  id                      :integer          not null, primary key
#  name                    :string
#  description             :string
#  item_number             :string
#  price                   :decimal(10, 2)   default(0.0), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  business_id             :integer
#  health_insurance_rebate :boolean          default(FALSE)
#  tax_id                  :integer
#  pricing_for_contact     :boolean          default(FALSE)
#  xero_account_code       :string
#  display_on_pricing_page :boolean          default(TRUE)
#  deleted_at              :datetime
#
# Indexes
#
#  index_billable_items_on_health_insurance_rebate  (health_insurance_rebate)
#  index_billable_items_on_tax_id                   (tax_id)
#

class BillableItem < ApplicationRecord
  include HasMarketplaceScope
  belongs_to :business
  belongs_to :tax

  has_and_belongs_to_many :practitioners, validate: false
  has_and_belongs_to_many :appointment_types, validate: false

  has_many :invoice_items, as: :invoiceable
  has_many :pricing_contacts, class_name: "BillableItemsContacts",
                              foreign_key: 'billable_item_id',
                              inverse_of: :item,
                              validate: false,
                              dependent: :delete_all

  accepts_nested_attributes_for :pricing_contacts, allow_destroy: true

  validates_presence_of :name, :price

  validates :item_number,
            presence: true,
            length: { maximum: 30 } # Item code in Xero limited to 30

  validates_length_of :name,
                      maximum: 150,
                      allow_nil: true,
                      allow_blank: true
  validates_length_of :description, maximum: 1000
  validates :price, presence: true,
            numericality: { greater_than: 0 }

  validate do
    if health_insurance_rebate? && !errors.include?(:item_number)
      unless HicapsItem.where(item_number: item_number).exists?
        errors.add(:item_number, 'is not a valid HICAPS item number')
      end
    end
  end

  delegate :name, :rate, to: :tax, prefix: true, allow_nil: true

  scope :not_deleted, -> { where(deleted_at: nil) }

  def tax_amount
    if tax
      tax.rate * price / 100
    else
      0
    end
  end

  def is_dva_item?
    true
  end

  def is_bulkbill_item?
    true
  end

  def self.ransackable_attributes(auth_object = nil)
    [
      'name',
      'item_number'
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
