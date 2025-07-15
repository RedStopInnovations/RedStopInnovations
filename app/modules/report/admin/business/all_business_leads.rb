module Report
  module Admin
    module Business
      class AllBusinessLeads
        class Options
          attr_accessor :start_date,
                        :end_date,
                        :business_id,
                        :page

          def initialize(options = {})
            @start_date = options[:start_date]
            @end_date = options[:end_date]
            @business_id = options[:business_id]
            @page = options[:page]
          end
        end

        attr_reader :options, :result

        def initialize(options)
          @options = options
          calculate
        end

        def calculate
          @result = {}
          query = ::Business.joins(
            "LEFT JOIN app_events ON app_events.data->>'business_id' = TEXT(businesses.id)"
            ).
            select('businesses.id, businesses.name, COUNT(app_events.id) AS leads_count').
            where('app_events.event_type' => AppEvent::TYPE_RCI)

          if options.business_id.present?
            query = query.where('businesses.id' => options.business_id)
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

          query = query.order('leads_count DESC, businesses.name ASC').group('businesses.id')

          @result[:paginated_businesses] = query.page(options.page)
        end
      end
    end
  end
end
