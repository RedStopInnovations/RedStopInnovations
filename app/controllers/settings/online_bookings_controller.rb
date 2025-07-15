module Settings
  class OnlineBookingsController < ApplicationController
    include HasABusiness

    def index
    end

    def generate_url
      generator = OnlineBookingsUrl::Generator.new current_business, parse_generate_url_options
      result = generator.generate

      render(
        json: result
      )
    end

    private

    def parse_generate_url_options
      options = OnlineBookingsUrl::Options.new

      options.page_type = params[:page_type]

      if options.page_type == 'practitioner'
        options.practitioner_id = params[:practitioner_id]
      elsif options.page_type == 'group'
        options.group_id = params[:group_id]
      end

      options
    end
  end
end
