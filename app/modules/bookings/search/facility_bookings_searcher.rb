module Bookings
  module Search
    class FacilityBookingsSearcher
      MINIMUM_ADVANCE_MINS = 60

      attr_reader :filters

      # Bookings::Search::FacilityBookingsFilter
      def initialize(filters)
        @filters = filters
      end

      def result
        make_result
      end

      private

      def base_scope
        Availability.facility.
          where(business_id: filters.business_id).
          where(contact_id: filters.contact_id).
          joins(:practitioner).
          select('availabilities.*').
          where(practitioners: { active: true })
      end

      def make_result
        avail_query = base_scope

        avail_query = filter_available_appointments(avail_query)
        avail_query = filter_profession(avail_query)
        avail_query = filter_date(avail_query)
        available_practitioner_ids = avail_query.pluck(:practitioner_id)
        avail_query = filter_practitioner(avail_query)
        avail_query = eager_load(avail_query)
        avail_query = order(avail_query)
        availabilities = paginate(avail_query)

        practitioner_ids = availabilities.map(&:practitioner_id).uniq
        practitioners = Practitioner.includes(
            :user, business: [:appointment_types],
            appointment_types: [:business]
          ).
          where(id: practitioner_ids).to_a

        results = []

        practs_avails_groups = availabilities.group_by do |avail|
          [avail.practitioner_id, avail.start_time.to_date]
        end

        practs_avails_groups.each do |group_key, availabilities|
          pract_id = group_key[0]
          practitioner = practitioners.find{ |p| p.id == pract_id }
          first_avail = availabilities.first

          appointment_types = practitioner.appointment_types.select do |at|
            !at.deleted? &&
              at.display_on_online_bookings? &&
              (at.availability_type_id == AvailabilityType::TYPE_FACILITY_ID)
          end

          results << OpenStruct.new(
            practitioner: practitioner,
            date: group_key[1],
            first_availability_start_time_ts: first_avail.start_time.to_i,
            availabilities: availabilities,
            appointment_types: appointment_types
          )
        end

        results.sort_by { |res| res.first_availability_start_time_ts }

        # Find available practitioners
        available_practitioners = Practitioner.
          active.
          where(id: available_practitioner_ids).
          to_a

        # Append the selected practitioner if he is not available
        if filters.practitioner_id && available_practitioner_ids.exclude?(filters.practitioner_id)
          available_practitioners << Practitioner.find(filters.practitioner_id)
        end

        result = {
          paginated: availabilities,
          results: results,
          available_practitioners: available_practitioners
        }

        result
      end

      def filter_available_appointments(query)
        query.where('availabilities.appointments_count < availabilities.max_appointment')
      end

      def filter_date(query)
        query.where(
          start_time: parse_date_range(filters.date)
        )
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
        if filters.practitioner_id
          query = query.where(availabilities: { practitioner_id: filters.practitioner_id })
        end
        query
      end

      def eager_load(query)
        query.includes(appointments: [:appointment_type])
      end

      def order(query)
        query.order(start_time: :asc)
      end

      def paginate(query)
        query.page(filters.page).per(50)
      end

      def parse_date_range(value)
        current_time = Time.current


        current_time = Time.current
        if ['next7days', 'next14days', 'next28days'].include?(filters.date)
          from_time = current_time + MINIMUM_ADVANCE_MINS.minutes
          days_advance = {
            'next7days' => 7,
            'next14days' => 14,
            'next28days' => 28,
          }[value]

          if days_advance.nil?
            days_advance = 14
          end
          end_time = (current_time + days_advance.days).end_of_day
        else
          specific_date = begin
            value.to_date
          rescue ArgumentError
            Time.zone.today
          end

          from_time = specific_date.beginning_of_day

          if from_time < current_time
            from_time = current_time + MINIMUM_ADVANCE_MINS.minutes
          end
          end_time = specific_date.end_of_day
        end

        from_time..end_time
      end
    end
  end
end
