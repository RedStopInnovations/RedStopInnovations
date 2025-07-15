module Bookings
  module Search
    class Searcher
      MINIMUM_ADVANCE_MINS = 30

      attr_reader :filters

      # @param filters Bookings::Search::Filters
      def initialize(filters)
        @filters = filters
      end

      def result
        avail_query = base_scope
        avail_query = filter_availability_type(avail_query)
        avail_query = filter_online_booking_enable(avail_query)
        avail_query = filter_profession(avail_query)
        avail_query = filter_date(avail_query)

        if filters.availability_type == 'Home visit'
          # TODO: constanize
          avail_query = filter_location(avail_query)
        end

        avail_query = filter_business(avail_query)

        avail_query = filter_practitioner(avail_query)

        avail_query = filter_practitioner_group(avail_query)

        avail_query = filter_available_appointments(avail_query)

        avail_query = eager_load(avail_query)
        avail_query = order(avail_query)

        make_result(paginate(avail_query))
      end

      private

      def filtered_availability_type
        @filtered_availability_type ||= AvailabilityType[filters.availability_type]
      end

      def filter_availability_type(query)
        query.where(
          availabilities: {
            availability_type_id: filtered_availability_type.id
          }
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

      def filter_date(query)
        current_time = Time.current

        if filters.date == 'next30days'
          from_time = current_time + MINIMUM_ADVANCE_MINS.minutes
          end_time = (current_time + 30.days).end_of_day
        elsif filters.date == 'next14days'
          from_time = current_time + MINIMUM_ADVANCE_MINS.minutes
          end_time = (current_time + 14.days).end_of_day
        elsif filters.date == 'next7days'
          from_time = current_time + MINIMUM_ADVANCE_MINS.minutes
          end_time = (current_time + 7.days).end_of_day
        elsif filters.date == 'next2days'
          from_time = current_time + MINIMUM_ADVANCE_MINS.minutes
          end_time = (current_time + 1.days).end_of_day
        else
          specific_date = parse_specific_date_filter(filters.date)
          from_time = specific_date.beginning_of_day

          if from_time < current_time
            from_time = current_time + MINIMUM_ADVANCE_MINS.minutes
          end
          end_time = specific_date.end_of_day
        end

        query.where(
          start_time: from_time..end_time
        )
      end

      def filter_location(query)
        if filters.location.present?
          location_coord = Geocoder.coordinates "#{filters.location}, #{filters.country}"
          query = query.near(
            location_coord,
            :service_radius,
            order: false
          ).order(
            'start_time ASC', 'distance ASC'
          )

        end
        query
      end

      def filter_business(query)
        if filters.business_id
          query = query.where(availabilities: { business_id: filters.business_id })
        end
        query
      end

      def filter_practitioner(query)
        if filters.practitioner_id
          query = query.where(availabilities: { practitioner_id: filters.practitioner_id })
        end
        query
      end

      def filter_practitioner_group(query)
        if filters.group_id
          group = Group.find_by(id: filters.group_id)
          if group
            query = query.where(
              practitioners: {
                id: group.practitioner_ids
              }
            )
          end
        end

        query
      end

      def filter_available_appointments(query)
        if filtered_availability_type.id == AvailabilityType::TYPE_HOME_VISIT_ID
          query.where('availabilities.appointments_count < availabilities.max_appointment')
        else
          query
        end
      end

      def filter_online_booking_enable(query)
        if filters.online_bookings_enable
          query = query.where('availabilities.allow_online_bookings' => true).
            where(
              practitioners: {
                allow_online_bookings: true
              }
            )
        end
        query
      end

      def eager_load(query)
        query.includes(:business, :practitioner)
      end

      def base_scope
        query = Availability.
          joins(:practitioner).
          select('availabilities.*').
          where(
            practitioners: {
              active: true,
              country: filters.country
            }
          )

        # Skip filter approved practitioner if url specified a business or practitioner
        unless filters.practitioner_id || filters.business_id || filters.group_id
          query = query.where(
            practitioners: {
              active: true,
              approved: true,
              public_profile: true,
              country: filters.country
            }
          )
        end

        query
      end

      def parse_specific_date_filter(value)
        if value.blank?
          Time.zone.today
        else
          case value
          when 'today'
            Time.zone.today
          when 'tomorrow'
            Time.zone.tomorrow
          else
            begin
              # Date.strptime(filters.date, '%Y-%m-%d')
              filters.date.to_date
            rescue ArgumentError
              Time.zone.today
            end
          end
        end
      end

      def make_result(availabilities)
        practitioner_ids = availabilities.map(&:practitioner_id).uniq
        practitioners = Practitioner.includes(
            :user,
            :business,
            :appointment_types
          ).
          where(id: practitioner_ids).to_a

        results = []
        # TODO: this is a bad solution for collect first available.
        # Need to replace by SQL query.

        if ['next2days', 'next7days', 'next14days', 'next30days'].include?(filters.date)
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
                (at.availability_type_id == filtered_availability_type.id)
            end

            if appointment_types.empty?
              next
            end

            results << OpenStruct.new(
              practitioner: practitioner,
              date: group_key[1],
              first_availability_start_time_ts: first_avail.start_time.to_i,
              availabilities: availabilities
            )
          end
        else
          practitioners.each do |pract|
            pract_avails = availabilities.select { |av| av.practitioner_id == pract.id }

            appointment_types = pract.appointment_types.select do |at|
              !at.deleted? &&
                at.display_on_online_bookings? &&
                (at.availability_type_id == filtered_availability_type.id)
            end

            if appointment_types.empty?
              next
            end

            first_avail = pract_avails.first

            results << OpenStruct.new(
              practitioner: pract,
              date: first_avail.start_time.to_date,
              first_availability_start_time_ts: first_avail.start_time.to_i,
              availabilities: pract_avails,
              appointment_types: appointment_types
            )
          end
        end

        results.sort_by { |res| res.first_availability_start_time_ts }

        result = {
          paginated: availabilities,
          results: results
        }

        result
      end

      def order(query)
        query.order(start_time: :asc)
      end

      def paginate(query)
        query.page(filters.page).per(50)
      end
    end
  end
end
