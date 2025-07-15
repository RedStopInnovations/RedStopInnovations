# == Schema Information
#
# Table name: patient_stripe_customers
#
#  id                      :integer          not null, primary key
#  patient_id              :integer          not null
#  stripe_customer_id      :string           not null
#  stripe_owner_account_id :string           not null
#  card_last4              :string           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_patient_stripe_customers_on_patient_id  (patient_id)
#

class PatientStripeCustomer < ApplicationRecord
  belongs_to :patient, -> { with_deleted }, inverse_of: :stripe_customer, touch: true

  validates_presence_of :patient,
                        :stripe_customer_id,
                        :stripe_owner_account_id,
                        :card_last4
end
