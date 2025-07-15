# == Schema Information
#
# Table name: invoices
#
#  id                    :integer          not null, primary key
#  issue_date            :date
#  subtotal              :decimal(10, 2)   default(0.0)
#  tax                   :decimal(10, 2)   default(0.0)
#  discount              :decimal(10, 2)   default(0.0)
#  amount                :decimal(10, 2)   default(0.0)
#  notes                 :text
#  status                :boolean
#  date_closed           :date
#  outstanding           :decimal(10, 2)   default(0.0)
#  appointment_id        :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  patient_id            :integer
#  practitioner_id       :integer
#  business_id           :integer
#  invoice_number        :string           default(""), not null
#  deleted_at            :datetime
#  invoice_to            :text
#  patient_case_id       :integer
#  invoice_to_contact_id :integer
#  xero_invoice_id       :string
#  last_send_patient_at  :datetime
#  provider_number       :string
#  service_ids           :integer          default([]), is an Array
#  diagnose_ids          :integer          default([]), is an Array
#  last_send_at          :datetime
#  amount_ex_tax         :decimal(10, 2)   default(0.0), not null
#  public_token          :string
#  last_send_contact_at  :datetime
#  outstanding_reminder  :json
#  message               :text
#  service_date          :date
#  task_id               :integer
#
# Indexes
#
#  index_invoices_on_appointment_id                  (appointment_id)
#  index_invoices_on_business_id                     (business_id) WHERE (deleted_at IS NULL)
#  index_invoices_on_business_id_and_invoice_number  (business_id,invoice_number)
#  index_invoices_on_deleted_at                      (deleted_at)
#  index_invoices_on_invoice_number                  (invoice_number)
#  index_invoices_on_invoice_to_contact_id           (invoice_to_contact_id)
#  index_invoices_on_patient_case_id                 (patient_case_id)
#  index_invoices_on_patient_id                      (patient_id)
#  index_invoices_on_practitioner_id                 (practitioner_id)
#  index_invoices_on_task_id                         (task_id)
#

class Invoice < ApplicationRecord
  include RansackAuthorization::Invoice
  include DeletionRecordable
  acts_as_paranoid
  has_secure_token :public_token

  auto_strip_attributes :notes, :message, nullify: true

  has_paper_trail(
    only: [
      :issue_date, :appointment_id, :practitioner_id, :patient_id,
      :invoice_to_contact_id, :patient_case_id, :outstanding, :amount
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

  belongs_to :business
  belongs_to :appointment, -> { with_deleted }
  belongs_to :practitioner
  belongs_to :patient, -> { with_deleted }
  belongs_to :task
  belongs_to :patient_case
  belongs_to :invoice_to_contact, class_name: "Contact"

  has_many :items, -> { order(created_at: :asc) },
           class_name: 'InvoiceItem',
           inverse_of: :invoice

  has_one :medipass_quote, dependent: :destroy
  has_many :payment_allocations
  has_many :payments, through: :payment_allocations
  has_many :hicaps_transactions, through: :payments
  has_many :medipass_transactions
  has_many :account_statement_items, as: :source
  has_many :account_statements,
           through: :account_statement_items,
           source: :account_statement

  has_one :pending_medipass_transaction,
           -> { pending },
            class_name: 'MedipassTransaction'

  accepts_nested_attributes_for :items,
    reject_if: ->attrs { attrs[:invoiceable_id].blank? && attrs[:quantity].blank? &&
      attrs[:unit_price].blank? },
    allow_destroy: true

  validates_presence_of :patient

  validates :notes,
            length: { maximum: 500 },
            allow_nil: true,
            allow_blank: true

  validates :message,
            length: { maximum: 500 },
            allow_nil: true,
            allow_blank: true

  scope :paid, -> { where(outstanding: 0) }
  scope :not_paid, -> { where.not(outstanding: 0) }

  def services
    business.invoice_shortcuts.services.where(id: service_ids)
  end

  def diagnosis
    business.invoice_shortcuts.diagnoses.where(id: diagnose_ids)
  end

  def update_outstanding_amount
    paid_amount = payment_allocations.sum(:amount)
    outstanding_amount = paid_amount > amount ? 0 : (amount - paid_amount)

    update_attribute :outstanding, outstanding_amount
  end

  def payable?
    !paid?
  end

  def paid
    outstanding == 0
  end

  def paid?
    outstanding == 0
  end

  def tax_amount
    items.sum(&:tax_amount).round 2
  end

  def associated_patient_id
    patient.id
  end

  def outstanding_reminder_enable?
    outstanding_reminder['enable'] == true
  end
end
