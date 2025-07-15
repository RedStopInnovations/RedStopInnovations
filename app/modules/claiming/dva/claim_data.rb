module Claiming
  module Dva
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
          type: 'DVA',
          flags: {
            serviceType: Util.profession_to_service_type(practitioner.profession)
          },
          patient: {
            dva: {
              number: patient.dva_file_number
            },
            dateOfBirth: patient.dob.strftime('%Y-%m-%d'),
            gender: (patient.gender == 'Male' ? 'M' : 'F'),
            name: {
              first: patient.first_name,
              family: patient.last_name
            }
          },
          provider: {
            servicing: practitioner.medicare,
            payee: practitioner.medicare
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

        # TODO: only home visit support for now
        if appointment.appointment_type.home_visit?
          data[:location] = { type: 'V' }
        end
        data
      end
    end
  end
end
