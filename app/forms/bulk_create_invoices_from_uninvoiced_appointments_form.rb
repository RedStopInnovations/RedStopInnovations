class BulkCreateInvoicesFromUninvoicedAppointmentsForm < BaseForm
  attr_accessor :business

  class Invoice
    include Virtus.model
    include ActiveModel::Model

    attribute :appointment_id, Integer
    attribute :send_after_create, Boolean
    attribute :patient_case_id, Integer
  end

  attribute :invoices, Array[Invoice]

  validate do
    if invoices.size > App::MAX_BULK_CREATE_INVOICES
      errors.add(:base, "Number of appointments must not exceed #{App::MAX_BULK_CREATE_INVOICES}")
    else
      invoices.each do |invoice|
        appt = business.appointments.find_by(id: invoice.appointment_id)

        if appt.nil?
          errors.add(:base, 'Some appointments does not exist')
        else
          if invoice.patient_case_id.present? && !appt.patient.patient_cases.exists?(id: invoice.patient_case_id)
            errors.add(:base, 'Some client case is mismatch')
          end
        end
      end
    end
  end
end