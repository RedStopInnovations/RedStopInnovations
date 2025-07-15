module Api
  module V1
    class TreatmentSerializer < BaseSerializer
      type 'treatment_notes'

      attributes  :name,
                  :status,
                  :sections,
                  :updated_at,
                  :created_at

      belongs_to :patient do
        link :self do
          @url_helpers.api_v1_patient_url(@object.patient_id)
        end
      end

      belongs_to :appointment do
        if @object.appointment_id?
          link :self do
            @url_helpers.api_v1_appointment_url(@object.appointment_id)
          end
        end
      end

      belongs_to :author do
        if @object.author_id?
          link :self do
            @url_helpers.api_v1_user_url(@object.author_id)
          end
        end
      end

      link :self do
        @url_helpers.api_v1_treatment_note_url(@object.id)
      end
    end
  end
end
