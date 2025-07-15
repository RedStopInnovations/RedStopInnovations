module Api
  module V1
    class AppointmentTypeSerializer < BaseSerializer
      type 'appointment_types'

      attributes :name,
                 :description,
                 :duration,
                 :reminder_enable,
                 :deleted_at,
                 :updated_at,
                 :created_at

      attribute :availability_type do
        ::AvailabilityType[@object.availability_type_id]&.uid
      end

      link :self do
        @url_helpers.api_v1_appointment_type_url(@object.id)
      end
    end
  end
end
