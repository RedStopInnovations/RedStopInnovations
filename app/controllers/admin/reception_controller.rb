module Admin
  class ReceptionController < BaseController
    before_action do
      authorize! :read, :reception_pages
    end

    def index
      redirect_to admin_reception_search_patient_path
    end

    def search_patient
      @patients = []
      if params[:q].present?
        @patients =
          Patient.
          includes(:business).
          where(businesses: {active: true}).
          ransack(
            first_name_or_last_name_or_full_name_or_email_or_mobile_or_phone_cont: params[:q].to_s.strip
          ).
          result.
          page(params[:page])
      end
    end

    def search_practitioner
      ransack_q = {}
      if params[:profession].present?
        ransack_q[:profession_eq] = params[:profession].to_s.strip
      end

      if params[:q].present?
        ransack_q[:first_name_or_last_name_or_full_name_or_email_cont] = params[:q].to_s.strip
      end

      practitioners_query = Practitioner.approved.ransack(ransack_q).result
      if params[:address].present?
        coordinates = Geocoder.coordinates params[:address]
        practitioners_query = practitioners_query.near(coordinates, 30, unit: :km)
      end

      @practitioners = practitioners_query.order(last_name: :asc).page(params[:page])
    end

    def search_business
      @businesses = []
      if params[:q].present?
        @businesses = Business.active.ransack(
          name_or_email_or_city_cont: params[:q].to_s.strip
        ).result.page(params[:page])
      end
    end

    def search_appointment
      query = Availability.where('start_time BETWEEN ? AND ?', Time.zone.now.beginning_of_day, Date.current + 60).
              order(:start_time)

      availability_type_id = params[:availability_type_id].to_i

      query = query.where(availability_type_id: availability_type_id)
                   .where(allow_online_bookings: true)
                   .joins(:practitioner)
                   .where(practitioners: { approved: :true })

      if params[:profession].present?
        query = query.where(practitioners: { profession: params[:profession].to_s })
      end

      if (availability_type_id == AvailabilityType::TYPE_HOME_VISIT_ID) &&
          params[:patient_address].present?

        coordinates = Geocoder.coordinates params[:patient_address]
        query = query.near(coordinates, :service_radius, unit: :km)
      end

      query = query.preload(:practitioner)

      @availabilities = query.page(params[:page])
    end
  end
end
