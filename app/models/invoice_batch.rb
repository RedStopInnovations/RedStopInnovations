class InvoiceBatch < ApplicationRecord
  self.table_name = 'invoice_batches'

  STATUS_PENDING = 'Pending'
  STATUS_IN_PROGRESS = 'In-Progress'
  STATUS_COMPLETE = 'Complete'
  STATUS_ERROR = 'Error'

  has_paper_trail(
    only: [:batch_number, :notes, :status, :start_date, :end_date, :options],
    on: [:create, :update, :destroy],
    versions: {
      class_name: 'PaperTrailVersion'
    }
  )

  belongs_to :business
  belongs_to :author, class_name: 'User'
  has_many :invoice_batch_items
  has_many :invoices, through: :invoice_batch_items

  validates :batch_number, presence: true, uniqueness: { scope: :business_id }
  validates :status, presence: true
  validates :start_date, :end_date, presence: true

  before_validation :generate_batch_number, on: :create

  private

  def generate_batch_number
    return if batch_number.present?

    batch_count = business.invoice_batches.count
    next_number = batch_count + 1
    self.batch_number = "BATCH-#{next_number.to_s.rjust(5, '0')}"
  end
end
