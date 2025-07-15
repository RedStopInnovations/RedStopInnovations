module Physitrack
  module Sso
    module QueryBuilder
      def self.build_patient_creation_query(patient, token)
        query = {
          data: {
            token: token,
            patient: {
              id: patient.id,
              first_name: patient.first_name,
              last_name: patient.last_name
            }
          }
        }

        additional_patient_info = {
          email: patient.email,
          title: patient.male? ? 'mr' : patient.female? ? 'ms' : nil,
          birth_year: patient.dob.try(:year),
          mobile_phone: patient.mobile_formated
          # diagnosis_code
        }

        additional_patient_info.compact

        query[:data][:patient] = query[:data][:patient].merge(additional_patient_info)

        query
      end
    end
  end
end
