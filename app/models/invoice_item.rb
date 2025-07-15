# == Schema Information
#
# Table name: invoice_items
#
#  id                :integer          not null, primary key
#  invoice_id        :integer          not null
#  quantity          :decimal(10, 2)   not null
#  unit_price        :decimal(10, 2)   default(0.0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  invoiceable_type  :string
#  invoiceable_id    :integer
#  unit_name         :string
#  tax_name          :string
#  tax_rate          :decimal(10, 2)
#  amount            :decimal(10, 2)   default(0.0)
#  xero_line_item_id :string
#  item_number       :string
#
# Indexes
#
#  index_invoice_items_on_invoice_id                           (invoice_id)
#  index_invoice_items_on_invoiceable_id_and_invoiceable_type  (invoiceable_id,invoiceable_type)
#

class InvoiceItem < ApplicationRecord
  belongs_to :invoice, inverse_of: :items
  belongs_to :invoiceable, polymorphic: true

  validates_presence_of :invoiceable, :invoice, :quantity, :unit_price

  validates :quantity,
            presence: true,
            numericality: { greater_than: 0 }

  validates :unit_price,
            presence: true,
            numericality: { greater_than: 0 }

  scope :billable_item, -> { where(invoiceable_type: BillableItem.name) }
  scope :product_item, -> { where(invoiceable_type: Product.name) }

  # TODO: move to the service
  before_save :assign_total_amount

  def tax_amount
    if tax_rate
      tax_rate * unit_price * quantity / 100
    else
      0
    end
  end

  def item_code
    item_number
  end

  # TODO: add description column and editable in invoice form.
  def description
    invoiceable.name
  end

  # Refactored methods
  def calculate_total_amount
    calculate_amount_ex_tax + calculate_tax_amount
  end

  def calculate_amount_ex_tax
    quantity * unit_price
  end

  def calculate_tax_amount
    if tax_rate
      tax_rate * unit_price * quantity / 100
    else
      0
    end
  end

  private

  def assign_total_amount
    self.amount = calculate_total_amount
  end
end
