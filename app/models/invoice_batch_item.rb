class InvoiceBatchItem < ApplicationRecord
  self.table_name = 'invoice_batch_items'

  STATUS_PENDING = 'Pending'
  STATUS_SKIPPED = 'Skipped'
  STATUS_CREATED = 'Created'
  STATUS_ERROR   = 'Error'

  belongs_to :invoice_batch
  belongs_to :appointment, -> { with_deleted }, optional: true
  belongs_to :invoice, optional: true
end
