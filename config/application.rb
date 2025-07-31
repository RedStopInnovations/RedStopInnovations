require_relative "boot"

require "rails/all"

require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Tracksy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Config generator to skip tests, assets, helper and stylesheet
    config.generators do |g|
      g.template_engine :erb
      g.test_framework nil # TODO: update with your test framework
      g.assets false
      g.helper false
      g.stylesheets false
    end

    # Set base url for url generator
    config.action_mailer.default_url_options = {
      host: ENV.fetch('BASE_URL', 'http://localhost:3000')
    }
    config.action_controller.asset_host = ENV.fetch('BASE_URL', 'http://localhost:3000')
    config.action_mailer.asset_host = ENV.fetch('BASE_URL', 'http://localhost:3000')
    config.autoload_paths << Rails.root.join('app', 'modules')
    config.autoload_paths << Rails.root.join('app', 'serializers')
    config.autoload_paths << Rails.root.join('app')

    config.i18n.enforce_available_locales = false
    config.i18n.available_locales = ['en-AU', 'en-US', 'en-GB', 'en-GB']
    config.i18n.default_locale = :'en-AU'

    config.after_initialize do |app|
      unless config.consider_all_requests_local
        app.routes.append { match '*a', to: 'application#render_not_found', via: :all }
      end
    end

    # config.active_record.yaml_column_permitted_classes = [Symbol, Hash, Array, ActiveSupport::HashWithIndifferentAccess, Date, ActiveSupport::TimeWithZone, Time]
    config.active_record.use_yaml_unsafe_load = true

    Rails.application.routes.default_url_options[:host] = ENV.fetch('BASE_URL', 'http://localhost:3000')

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '/api/v1/*', :headers => :any, :methods => [:get, :post, :options]
      end
    end

    config.middleware.use Rack::Attack
    # require './app/middlewares/validate_request_params'
    # config.middleware.insert_before Rack::Head, ValidateRequestParams
  end
end
