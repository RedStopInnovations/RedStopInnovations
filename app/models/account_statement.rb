# == Schema Information
#
# Table name: account_statements
#
#  id           :integer          not null, primary key
#  business_id  :integer          not null
#  source_id    :integer          not null
#  source_type  :string           not null
#  public_token :string           not null
#  start_date   :date             not null
#  end_date     :date             not null
#  options      :jsonb
#  number       :string           not null
#  deleted_at   :datetime
#  pdf          :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  last_send_at :datetime
#
# Indexes
#
#  account_statements_business_id_not_deleted_idx         (business_id) WHERE (deleted_at IS NULL)
#  index_account_statements_on_business_id                (business_id)
#  index_account_statements_on_source_id_and_source_type  (source_id,source_type)
#

class AccountStatement < ApplicationRecord
  include RansackAuthorization::AccountStatement
  include DeletionRecordable
  has_secure_token :public_token
  mount_uploader :pdf, AccountStatementPdfUploader

  belongs_to :source, -> { with_deleted }, polymorphic: true
  belongs_to :business

  has_many :items, class_name: 'AccountStatementItem'
  has_many :invoices, through: :items, source: :source, source_type: 'Invoice'
  has_many :appointments, through: :items, source: :source, source_type: 'Appointment'
  has_many :payments, through: :items, source: :source, source_type: 'Payment'

  before_create :generate_number

  scope :not_deleted, -> { where(deleted_at: nil) }

  def associated_patient_id
    if source_type == Patient.name
      source_id
    end
  end

  private

  def generate_number
    if number.blank?
      total_business_stmts = 0
      prefix = nil
      case source
      when Patient
        total_business_stmts = business.patient_account_statements.count
        prefix = 'PAS'
      when Contact
        total_business_stmts = business.contact_account_statements.count
        prefix = 'CAS'
      end

      self.number = "#{prefix}#{(total_business_stmts + 1).to_s.rjust(4, '0')}"
    end
  end
end
