module SearchAppointment
  class Searcher
    MAX_DAYS_ADVANCED = 60
    DEFAULT_DAYS_AHEAD = 7
    ALLOWED_AVAILABILITY_TYPES = [
      AvailabilityType::TYPE_HOME_VISIT_ID,
      AvailabilityType::TYPE_FACILITY_ID,
      AvailabilityType::TYPE_GROUP_APPOINTMENT_ID
    ]

    attr_reader :filters

    def initialize(filters)
      @filters = filters
    end

    def result
      result = {}
      avail_query = base_scope
      avail_query = filter_availability_type(avail_query)
      avail_query = filter_available_appointments(avail_query)
      avail_query = filter_date_range(avail_query)
      avail_query = filter_profession(avail_query)
      avail_query = filter_practitioner(avail_query)
      avail_query = filter_practitioner_group(avail_query)
      avail_query = order(avail_query)

      loc_coordinates = nil
      if filters.availability_type_id.present?
        if filters.availability_type_id == AvailabilityType::TYPE_HOME_VISIT_ID
          if filters.patient_id.present?
            patient = business.patients.with_deleted.find_by(id: filters.patient_id)
            if patient && patient.geocoded?
              loc_coordinates = patient.to_coordinates
            end
          elsif filters.location.present?
            loc_coordinates = Geocoder.coordinates filters.location
          end
        end
      end

      if loc_coordinates
        avail_query = avail_query.near(loc_coordinates, filters.distance, unit: :km)
        result[:nearby_practitioners] = find_nearby_practitioners
      else
        result[:nearby_practitioners] = []
      end

      avail_query = avail_query.preload(:practitioner)

      result[:availabilities] = avail_query.page(filters.page).per(filters.per_page)

      result
    end

    private

    def business
      @business ||= Business.find(filters.business_id)
    end

    def base_scope
      # @TODO: eager load too much data
      Availability.where(business_id: business.id).
        joins(:practitioner).
        where(practitioners: { active: true}).
        includes(:contact, practitioner: [:user, :business_hours], appointments: [
          :appointment_type, :practitioner, :patient, :treatment_note,
          :arrival, :invoice,
          :bookings_answers
        ])
    end

    def filter_availability_type(query)
      if filters.availability_type_id.present? && ALLOWED_AVAILABILITY_TYPES.include?(filters.availability_type_id)
        query.where(availability_type_id: filters.availability_type_id)
      else
        query.where(availability_type_id: ALLOWED_AVAILABILITY_TYPES)
      end
    end

    def filter_date_range(query)
      if filters.start_date.present?
        start_time = filters.start_date.to_date.beginning_of_day
        end_time =
          if filters.end_date.present?
            filters.end_date.to_date.end_of_day
          else
            DEFAULT_DAYS_AHEAD.days.from_now
          end
        range = start_time..end_time
      else
        range = Time.current.beginning_of_day..MAX_DAYS_ADVANCED.days.from_now
      end

      query.where(start_time: range)
    end

    def filter_profession(query)
      if filters.profession.present?
        query = query.where(
          practitioners: { profession: filters.profession }
        )
      end
      query
    end

    def filter_practitioner(query)
      if filters.practitioner_id.present?
        pract = business.practitioners.find(filters.practitioner_id)

        query = query.where(
          practitioners: { id: pract.id }
        )
      end
      query
    end

    def filter_practitioner_group(query)
      if filters.practitioner_group_id.present?
        group = business.groups.find(filters.practitioner_group_id)
        query = query.where(
          practitioners: { id: group.practitioner_ids }
        )
      end
      query
    end

    def filter_available_appointments(query)
      query.where('availabilities.appointments_count < availabilities.max_appointment')
    end

    def order(query)
      query.order('start_time ASC')
    end

    def find_nearby_practitioners
      practitioners_query = business.
        practitioners.
        includes(:user).
        active

      if filters.profession.present?
        practitioners_query = practitioners_query.where(
          profession: filters.profession
        )
      end

      loc_coordinates = nil

      if filters.patient_id.present?
        patient = business.patients.with_deleted.find_by(id: filters.patient_id)
        if patient && patient.geocoded?
          loc_coordinates = patient.to_coordinates
        end
      elsif filters.location.present?
        loc_coordinates = Geocoder.coordinates filters.location
      end

      if loc_coordinates
        practitioners_query = practitioners_query.near(
          loc_coordinates,
          filters.distance,
          unit: :km
        )
      end

      practitioners_query.limit(10).load
    end
  end
end
