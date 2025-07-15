module Report
  module Admin
    module Analytics
      class EventsSummary
        class Options
          attr_accessor :name,
                        :tags,
                        :start_date,
                        :end_date,
                        :business_id,
                        :page

          def initialize(options = {})
            @start_date = options[:start_date]
            @end_date = options[:end_date]
            @name = options[:name]
            @tags = options[:tags]
            @page = options[:page]
          end
        end

        attr_reader :options, :results

        def initialize(options)
          @options = options
          calculate
        end

        private

        def calculate
          @results = {}

          events_query = Ahoy::Event.order(id: :desc)

          if options.name
            events_query = events_query.where(name: options.name)
          end

          if options.tags
            events_query = events_query.where("properties->>'tags' = ?", options.tags)
          end

          if options.start_date
            events_query = events_query.where('time >= ?', options.start_date.beginning_of_day)
          end

          if options.end_date
            events_query = events_query.where('time <= ?', options.end_date.end_of_day)
          end

          paginated_events = events_query.order(id: :desc).page(options.page)

          @results[:paginated_events] = paginated_events
        end

      end
    end
  end
end