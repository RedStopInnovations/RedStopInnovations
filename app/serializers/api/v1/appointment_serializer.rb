module Api
  module V1
    class AppointmentSerializer < BaseSerializer
      type 'appointments'

      attributes  :start_time,
                  :end_time,
                  :booked_online,

                  :status,
                  :notes,
                  :cancelled_at,
                  :deleted_at,
                  :updated_at,
                  :created_at

      belongs_to :patient do
        link :self do
          @url_helpers.api_v1_patient_url(@object.patient_id)
        end
      end

      belongs_to :appointment_type do
        link :self do
          @url_helpers.api_v1_appointment_type_url(@object.appointment_type_id)
        end
      end

      belongs_to :availability do
        link :self do
          @url_helpers.api_v1_availability_url(@object.availability_id)
        end
      end

      belongs_to :practitioner do
        link :self do
          @url_helpers.api_v1_practitioner_url(@object.practitioner_id)
        end
      end

      has_one :appointment_arrival do
        data do
          @object.arrival
        end
      end

      link :self do
        @url_helpers.api_v1_appointment_url(@object.id)
      end
    end
  end
end
