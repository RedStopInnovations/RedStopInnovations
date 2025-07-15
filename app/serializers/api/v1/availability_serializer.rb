module Api
  module V1
    class AvailabilitySerializer < BaseSerializer
      type 'availabilities'

      attributes  :start_time,
                  :end_time,

                  :address1,
                  :address2,
                  :city,
                  :state,
                  :postcode,
                  :country,
                  :max_appointment,
                  :service_radius,

                  :latitude,
                  :longitude,

                  :allow_online_bookings,
                  :updated_at,
                  :created_at

      attribute :availability_type do
        if @object.availability_type_id.present?
          ::AvailabilityType[@object.availability_type_id]&.uid
        end
      end

      has_many :appointments

      belongs_to :contact do
        if @object.contact_id?
          link :self do
            @url_helpers.api_v1_contact_url(@object.contact_id)
          end
        end
      end

      belongs_to :practitioner do
        link :self do
          @url_helpers.api_v1_practitioner_url(@object.practitioner_id)
        end
      end

      link :self do
        @url_helpers.api_v1_availability_url(@object.id)
      end

      meta do
        {
          appointments_count: @object.appointments_count
        }
      end
    end
  end
end
