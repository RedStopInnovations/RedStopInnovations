module OnlineBookingsUrl
  class Generator
    attr_reader :business, :options

    def initialize(business, options)
      @business = business
      @options = options
    end

    def generate
      result = {}

      if options.page_type == 'default'
        page_params = {
          business_id: business.id,
        }

        result = {
          url: Rails.application.routes.url_helpers.frontend_bookings_url(page_params)
        }

      elsif options.page_type == 'practitioner'
        practitioner = business.practitioners.find(options.practitioner_id)

        page_params = {
          business_id: business.id,
          practitioner_id: practitioner.id,
        }

        result = {
          url: Rails.application.routes.url_helpers.frontend_bookings_url(page_params),
        }

      elsif options.page_type == 'group'
        group = business.groups.find(options.group_id)

        page_params = {
          business_id: business.id,
          group_id: group.id,
        }

        result = {
          url: Rails.application.routes.url_helpers.frontend_bookings_url(page_params),
        }

      else
        raise ArgumentError, "Unknown page type: \"#{options.page_type}\""
      end

      result
    end
  end
end