class FormStripePayment < BaseForm
  attr_accessor :business

  attribute :patient_id, Integer
  attribute :invoice_ids, Array[Integer]
  attribute :stripe_token, String
  attribute :use_current_card, Boolean, default: true
  attribute :save_card, Boolean, default: false

  validates_presence_of :patient_id
  validates_presence_of :invoice_ids

  validate do
    unless errors.key?(:patient_id) || business.patients.exists?(id: patient_id)
      errors.add(:patient_id, 'The client is not exists')
    end
  end

  validate do
    unless errors.key?(:invoice_ids) || errors.key?(:patient_id)
      # Invoice must be associated with the client
      invoices_query = Invoice.where(id: invoice_ids)
      if invoices_query.pluck(:patient_id).uniq != [patient_id]
        errors.add(:invoice_ids, 'Some invoices are not associated with the client.')
      end

      if invoices_query.where('outstanding <= 0').count >= 1
        errors.add(:invoice_ids, 'Some invoices are paid already.')
      end
    end
  end

  validate do
    unless errors.key?(:patient_id)
      patient = Patient.find(patient_id)
      if use_current_card && patient.stripe_customer.blank?
        errors.add(:base, 'The client has not credit card added')
      end
    end
  end

  validate do
    if !use_current_card && stripe_token.blank?
      errors.add(:base, 'No credit card given.')
    end
  end
end
