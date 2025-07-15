module Report
  module Practitioners
    class Availability
      class Options
        attr_accessor :start_date,
                      :end_date,
                      :practitioner_ids,
                      :practitioner_group_ids,
                      :availability_type_ids,
                      :include_inactive_practitioner,
                      :page

        def initialize(options = {})
          @start_date = options[:start_date]
          @end_date = options[:end_date]
          @practitioner_ids = options[:practitioner_ids]
          @practitioner_group_ids = options[:practitioner_group_ids]
          @include_inactive_practitioner = options[:include_inactive_practitioner]
          @page = options[:page]
        end

        def to_params
          params = {
            start_date: start_date.strftime("%Y-%m-%d"),
            end_date: end_date.strftime("%Y-%m-%d"),
            practitioner_ids: practitioner_ids,
            practitioner_group_ids: practitioner_group_ids
          }

          if include_inactive_practitioner
            params[:include_inactive_practitioner] = 1
          end

          params
        end
      end

      attr_reader :business, :options, :results

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        calculate
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << [
            "Practitioner ID",
            "Practitioner",
            "Practitioner profession",
            "Practitioner group",
            "Availability date",
            "Availability start",
            "Availability end",
            "Availability type",
            "Availability subtype",
            "Location",
            "Name",
            "Description",
            "Contact",
            "Duration (hrs)",
            "Remaining availability (hrs)"
          ]

          availability_query.
            includes(:availability_subtype, :contact, practitioner: :groups).
            find_each do |avail|
              pract = avail.practitioner
              practitioner_group_col = pract.groups.to_a.map(&:name).join(';')
              duration_in_hrs = ((avail.end_time - avail.start_time).to_f / 3600).round(2)
              remaining_avail_in_hrs =
                if avail.cached_stats['remaining_availability_duration'].present?
                  (avail.cached_stats['remaining_availability_duration'].to_f / 3600).round(2)
                end

              csv << [
                pract.id,
                pract.full_name,
                pract.profession,
                practitioner_group_col,
                avail.start_time.strftime('%d %b %Y'),
                avail.start_time.strftime('%l:%M%P'),
                avail.end_time.strftime('%l:%M%P'),
                avail.availability_type.name,
                avail.availability_subtype.try(:name),
                [avail.city, avail.state].compact.join(', '),
                avail.name,
                avail.description,
                avail.contact&.business_name,
                duration_in_hrs,
                remaining_avail_in_hrs
              ]
            end
        end
      end

      private

      def calculate
        @results = {}

        @results[:paginated_availability] = availability_query.
          includes(:availability_subtype, practitioner: :user).
          order(start_time: :asc).
          page(options.page)

        @results[:total_availability_hours] = (availability_query.sum('EXTRACT (EPOCH FROM (end_time - start_time))').to_f / 3600).round(2)

        availability_hours_per_type = {}
        [
          AvailabilityType::TYPE_HOME_VISIT_ID,
          AvailabilityType::TYPE_FACILITY_ID,
          AvailabilityType::TYPE_NON_BILLABLE_ID,
          AvailabilityType::TYPE_GROUP_APPOINTMENT_ID
        ].each do |avail_type|
          if !@options.availability_type_ids.present? || @options.availability_type_ids.include?(avail_type)
            availability_hours_per_type[avail_type] = (availability_query.where(availability_type_id: avail_type).sum('EXTRACT (EPOCH FROM (end_time - start_time))').to_f / 3600).round(2)
          end
        end

        @results[:total_availability_hours_per_type] = availability_hours_per_type
      end

      def availability_query
        query = ::Availability.where(practitioner_id: report_practitioner_ids)

        if options.availability_type_ids.present?
          query = query.where(availability_type_id: options.availability_type_ids)
        end

        query = query.where("start_time >= ?", options.start_date.beginning_of_day).
                      where("end_time <= ?", options.end_date.end_of_day)
        query
      end

      def report_practitioner_ids
        query = Practitioner.where(business_id: business.id)

        if options.practitioner_ids.present?
          query = query.where(id: options.practitioner_ids)
        else
          if options.practitioner_group_ids.present?
            practitioner_ids = []

            business.groups.where(id: options.practitioner_group_ids).each do |group|
              practitioner_ids += group.practitioners.pluck(:id)
            end

            query = query.where(id: practitioner_ids)
          end

          unless options.include_inactive_practitioner
            query = query.active
          end
        end

        query.pluck :id
      end
    end
  end
end
