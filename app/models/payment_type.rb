# == Schema Information
#
# Table name: payment_types
#
#  id              :integer          not null, primary key
#  business_id     :integer          not null
#  name            :string           not null
#  type            :string           not null
#  myob_account_id :string
#  xero_account_id :string
#
# Indexes
#
#  index_payment_types_on_business_id           (business_id)
#  index_payment_types_on_business_id_and_type  (business_id,type) UNIQUE
#

class PaymentType < ApplicationRecord
  self.inheritance_column = nil

  TYPES = [
    HICAPS         = 'HICAPS',
    EFTPOS         = 'EFTPOS',
    CASH           = 'Cash',
    MEDICARE       = 'Medicare',
    WORKCOVER      = 'Workcover',
    DVA            = 'DVA',
    STRIPE         = 'Stripe',
    DIRECT_DEPOSIT = 'Direct deposit',
    CHEQUE         = 'Cheque',
    OTHER          = 'Other'
  ].freeze

  belongs_to :business

  validates_presence_of :business, :name, :type
end
