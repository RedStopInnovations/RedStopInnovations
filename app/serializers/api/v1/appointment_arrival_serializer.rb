module Api
  module V1
    class AppointmentArrivalSerializer < BaseSerializer
       type 'appointment_arrivals'

      attributes  :arrival_at,
                  :sent_at,
                  :travel_distance,
                  :travel_duration

      attribute :travel_distance do
        @object.travel_distance.to_i
      end

    end
  end
end