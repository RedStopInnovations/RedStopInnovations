module Api
  module V1
    class PatientContactSerializer < BaseSerializer
      type 'patient_contact_associations'

      attributes :contact_id,
                 :type,
                 :updated_at,
                 :created_at

      attribute :contact_id do
        @object.contact_id.to_s
      end

      belongs_to :patient do
        link :self do
          @url_helpers.api_v1_patient_url(@object.patient_id)
        end
      end

      belongs_to :contact do
        link :self do
          @url_helpers.api_v1_contact_url(@object.contact_id)
        end
      end
    end
  end
end
