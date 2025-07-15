module Claiming
  module BulkBill
    class VerifyPatientData
      attr_reader :patient

      def initialize(patient)
        @patient = patient
      end

      def data
        {
          type: 'Verify:Medicare',
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
          }
        }
      end
    end
  end
end
