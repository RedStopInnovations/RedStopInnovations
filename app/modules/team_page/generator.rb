module TeamPage
  class Generator
    attr_reader :business, :options
    def initialize(business, options)
      @business = business
      @options = options
    end

    def generate
      result = {}
      if options.page_type == 'team'
        page_params = {
          business_id: business.id,
          business_slug: business.name.parameterize,
        }

        if options.profession.present?
          page_params[:profession] = options.profession.to_s
        end

        result = {
          url: Rails.application.routes.url_helpers.iframe_team_page_url(page_params),
          iframe_url: Rails.application.routes.url_helpers.iframe_team_page_url(page_params.merge(_iframe: 1))
        }

      elsif options.page_type == 'single'
        practitioner = business.practitioners.find(options.practitioner_id)

        page_params = {
          business_id: business.id,
          business_slug: business.name.parameterize,
          practitioner_id: practitioner.id,
          practitioner_slug: practitioner.full_name.parameterize
        }

        result = {
          url: Rails.application.routes.url_helpers.iframe_team_practitioner_profile_page_url(page_params),
          iframe_url: Rails.application.routes.url_helpers.iframe_team_practitioner_profile_page_url(page_params.merge(_iframe: 1))
        }
      else
        raise ArgumentError, 'Unknown page type'
      end

      result
    end
  end
end