module Report
  module Admin
    module Business
      class BusinessLeads
        class Options
          attr_accessor :start_date,
                        :end_date,
                        :practitioner_ids,
                        :page

          def initialize(options = {})
            @start_date = options[:start_date]
            @end_date = options[:end_date]
            @practitioner_ids = options[:practitioner_ids]
            @page = options[:page]
          end
        end

        attr_reader :business, :options, :result

        def initialize(business, options)
          @business = business
          @options = options
          calculate
        end

        private

        def base_query_scope
          ::AppEvent.where(
            event_type: AppEvent::TYPE_RCI
          ).where("app_events.data->>'business_id' = ?", business.id.to_s)
        end

        def apply_filters(query)
          if options.practitioner_ids && options.practitioner_ids.size > 0
            query = query.where("app_events.data->>'source_type' = ?", 'Practitioner')
              .where("app_events.data->>'source_id' IN (?)", options.practitioner_ids)
          end

          if options.start_date
            query = query.where(
              'app_events.created_at >= ?', options.start_date.beginning_of_day
            )

            if options.end_date
              query = query.where(
                'app_events.created_at <= ?', options.end_date.end_of_day
              )
            end
          end

          query
        end

        def calculate
          @result = {}

          @result[:all_time_leads_count] = base_query_scope.count
          months_data = []
          query = base_query_scope
          query.
            where('created_at >= ?', 6.months.ago.beginning_of_month).
            group_by do |record|
              record.created_at.to_date.beginning_of_month
            end.
            each do |date_of_month, records|
            months_data << {
              date: date_of_month,
              leads_count: records.size
            }
          end

          @result[:monthly_leads_count_last_6_months] = months_data
          # OPTIMIZE: SQL query
          @result[:contact_info_types_chart_data] = build_contact_info_types_chart_data
          @result[:contact_source_pages_chart_data] = build_contact_source_pages_chart_data
          @result[:paginated_events] = apply_filters(query).order('created_at DESC').page(options.page)
        end

        def build_contact_info_types_chart_data
          query = apply_filters(base_query_scope)
          by_phone_count = query.
            where("data->>'contact_info_type' = ?", 'phone').
            count

          by_email_count = query.
            where("data->>'contact_info_type' = ?", 'email').
            count

          by_other_count = query.
            where("data->>'contact_info_type' NOT IN (?)", ['email', 'phone']).
            count

          {
            datasets: [
              {
                data: [by_phone_count, by_email_count, by_other_count]
              }
            ],
            labels: ['Phone', 'Email', 'Other']
          }
        end

        def build_contact_source_pages_chart_data
          data = []
          query = apply_filters(base_query_scope)
          country_prefixes = ['/au', '/uk', '/nz', '/us']
          [
            '',
            '/contact-us',
            '/pricing',
            '/bookings',
            '/team'
          ].map do |url_pattern|
            country_prefixes.map do |prefix|
              "#{prefix}#{url_pattern}"
            end
          end.
          each do |url_starts|
            data << query.
              where("data->>'url' IN (?)", url_starts).
              count
          end

          all_page_count = query.count
          data << all_page_count - data.sum
          {
            datasets: [
              {
                data: data
              }
            ],
            labels: [
              'Home',
              'Contact Us',
              'Pricing',
              'Online Booking',
              'Team profile',
              'Other'
            ]
          }
        end
      end
    end
  end
end
