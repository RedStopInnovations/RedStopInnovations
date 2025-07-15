module Claiming
  module BulkBill
    class ClaimData
      attr_reader :invoice

      def initialize(invoice)
        @invoice = invoice
      end

      def data
        patient = invoice.patient
        practitioner = invoice.practitioner
        appointment = invoice.appointment
        data = {
          type: 'BulkBill',
          flags: {
            serviceType: Util.profession_to_service_type(practitioner.profession)
          },
          patient: {
            medicare: {
              number: patient.medicare_card_number,
              ref: patient.medicare_card_irn
            },
            dateOfBirth: patient.dob.strftime('%Y-%m-%d'),
            gender: (patient.gender == 'Male' ? 'M' : 'F'),
            name: {
              first: patient.first_name,
              family: patient.last_name
            }
          },
          provider: {
            servicing: practitioner.medicare
          },
          items: []
        }

        invoice.items.each do |ii|
          data[:items] << {
            itemNumber: ii.item_number.to_s,
            chargeAmount: (ii.amount * 100).to_f,
            duration: appointment.appointment_type.duration,
            date: appointment.start_time.strftime('%Y-%m-%d')
          }
        end

        data
      end
    end
  end
end
