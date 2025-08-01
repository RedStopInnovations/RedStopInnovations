module Medipass
  # Represent the availability to request a Medipass payment for an invoice
  class PaymentAvailability
    attr_reader :invoice, :errors

    def initialize(invoice)
      @invoice = invoice
      @errors = {}
      check_patient(invoice.patient)
      check_invoice(invoice)
      check_practitioner(invoice.practitioner)
    end

    private

    def check_patient(patient)
      unless patient.medipass_member_id?
        errors[:patient] = 'The Medipass member info was not found for the client.'
      end
    end

    def check_practitioner(practitioner)
      if practitioner.nil?
        errors[:practitioner] = 'Cannot cannot determine the practitioner.'
      elsif practitioner.medicare.nil?
        errors[:practitioner] = 'The practitioner\'s provider number is not set.'
      end
    end

    def check_invoice(invoice)
      if invoice.items.length == 0
        errors[:invoice] = 'The invoice has no any items.'
        return
      end

      if invoice.appointment.nil?
        errors[:invoice] = 'The invoice is not attached to an appointment.'
        return
      end
    end

  end
end
