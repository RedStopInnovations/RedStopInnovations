# == Schema Information
#
# Table name: payments
#
#  id                         :integer          not null, primary key
#  payment_date               :date
#  eftpos                     :decimal(10, 2)   default(0.0)
#  hicaps                     :decimal(10, 2)   default(0.0)
#  cash                       :decimal(10, 2)   default(0.0)
#  medicare                   :decimal(10, 2)   default(0.0)
#  workcover                  :decimal(10, 2)   default(0.0)
#  dva                        :decimal(10, 2)   default(0.0)
#  other                      :decimal(10, 2)   default(0.0)
#  amount                     :decimal(10, 2)   default(0.0)
#  invoice_id                 :integer
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  patient_id                 :integer
#  payment_method             :string
#  payment_method_status      :boolean
#  payment_method_status_info :text
#  stripe_charge_id           :string
#  business_id                :integer
#  deleted_at                 :datetime
#  stripe_charge_amount       :decimal(10, 2)   default(0.0)
#  direct_deposit             :decimal(10, 2)   default(0.0)
#  cheque                     :decimal(10, 2)   default(0.0)
#  editable                   :boolean          default(TRUE)
#
# Indexes
#
#  index_payments_on_business_id  (business_id) WHERE (deleted_at IS NULL)
#  index_payments_on_deleted_at   (deleted_at)
#  index_payments_on_invoice_id   (invoice_id)
#  index_payments_on_patient_id   (patient_id)
#

class Payment < ApplicationRecord
  include DeletionRecordable
  PAYMENT_SOURCE_ATTRIBUTES = %i(
    eftpos hicaps cash medicare workcover dva direct_deposit cheque other
  )

  acts_as_paranoid

  has_paper_trail(
    only: [
      :payment_date, :patient_id, :amount, :payment_method, :deleted_at
    ],
    on: [:create, :update, :destroy],
    versions: {
      class_name: 'PaperTrailVersion'
    }
  )

  has_one :deleted_version, -> { where(event: 'destroy') },
    class_name: 'PaperTrailVersion',
    as: :item

  has_one :created_version, -> { where(event: 'create') },
    class_name: 'PaperTrailVersion',
    as: :item

  has_one :hicaps_transaction, dependent: :destroy
  belongs_to :invoice, -> { with_deleted }, optional: true, touch: true
  belongs_to :patient, -> { with_deleted }
  belongs_to :business

  has_many :payment_allocations, foreign_key: :payment_id
  has_many :invoices, through: :payment_allocations

  accepts_nested_attributes_for :payment_allocations

  before_save :calculate_total_amount

  def associated_patient_id
    patient.id
  end

  private

  def calculate_total_amount
    total = stripe_charge_amount

    PAYMENT_SOURCE_ATTRIBUTES.each do |attr|
      total += self.send(attr) if self.send(:"#{attr}?")
    end

    self.amount = total
  end
end
