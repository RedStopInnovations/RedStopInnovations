module Claiming
  module Dva
    class VerifyPatientData
      attr_reader :patient

      def initialize(patient)
        @patient = patient
      end

      def data(options = {})
        {
          type: 'Verify:DVA',
          patient: {
            dva: {
              number: patient.dva_file_number
              # TODO: not sure more required fields for DVA verification
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
