class CreateAttendanceProofExportForm < BaseForm
  attr_accessor :business

  attribute :invoice_id, Integer
  attribute :account_statement_id, Integer
  attribute :description, String

  validates :description, presence: true, length: {maximum: 300}
end