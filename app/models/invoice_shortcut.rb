# == Schema Information
#
# Table name: invoice_shortcuts
#
#  id          :integer          not null, primary key
#  content     :text
#  business_id :integer
#  category    :string
#
# Indexes
#
#  index_invoice_shortcuts_on_business_id  (business_id)
#

class InvoiceShortcut < ApplicationRecord
  CATEGORIES = [
    CATEGORY_DIAGNOSE = "Diagnose",
    CATEGORY_SERVICE = "Service"
  ]

  scope :diagnoses, -> { where(category: CATEGORY_DIAGNOSE )}
  scope :services, -> { where(category: CATEGORY_SERVICE)}

  validates :content, presence: true
end
