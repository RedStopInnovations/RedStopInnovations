module Settings
  class IframesController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    def referral
    end

    def team_page
    end

    def generate_team_page_url
      generator = TeamPage::Generator.new current_business, parse_team_page_generate_options
      result = generator.generate

      render(
        json: result
      )
    end

    private

    def parse_team_page_generate_options
      options = TeamPage::Options.new

      options.page_type = params[:page_type]

      if options.page_type == 'team'
        if params[:profession]
          options.profession = params[:profession].to_s
        end
      elsif options.page_type == 'single'
        options.practitioner_id = params[:practitioner_id]
      end

      options
    end
  end
end