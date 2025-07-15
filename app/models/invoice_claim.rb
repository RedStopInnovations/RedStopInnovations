# == Schema Information
#
# Table name: invoice_claims
#
#  id                :integer          not null, primary key
#  invoice_id        :integer          not null
#  type              :string           not null
#  status            :string           not null
#  transaction_id    :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  claim_id          :string
#  medicare_claim_id :string
#
# Indexes
#
#  index_invoice_claims_on_invoice_id  (invoice_id)
#  index_invoice_claims_on_type        (type)
#

class InvoiceClaim < ApplicationRecord
  self.inheritance_column = nil

  TYPES = [
    TYPE_DVA = 'DVA',
    TYPE_BULK_BILL = 'Bulk Bill'
  ]

  STATUSES = [
    STATUS_OK = 'OK',
    STATUS_NEW = 'NEW',
    STATUS_INVALID = 'INVALID',
    STATUS_COMPLETE = 'COMPLETE',
    STATUS_PROCESSED = 'PROCESSED',
    STATUS_REJECTED = 'REJECTED'
  ]

  belongs_to :invoice, -> { with_deleted }
  validates_presence_of :invoice_id, :type, :status, :claim_id

  scope :dva, -> { where type: TYPE_DVA }
  scope :bulk_bill, -> { where type: TYPE_BULK_BILL }
  scope :not_final_status, -> { where(status: [STATUS_OK, STATUS_NEW, STATUS_PROCESSED]) }
end
