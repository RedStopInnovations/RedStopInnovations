ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
require 'sidekiq/testing'

Rails.application.eager_load!
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Request::ApiHelper, type: :request
  config.include ControllerAuthHelpers, type: :controller

  config.use_transactional_fixtures = false

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!

  config.render_views

  config.before :suite do
    DatabaseCleaner.clean_with :truncation
  end

  config.before :each do
    Sidekiq::Worker.clear_all
    DatabaseCleaner.strategy = :transaction
  end

  config.before :each, js: true do
    DatabaseCleaner.strategy = :truncation
  end

  config.before :each do
    DatabaseCleaner.start
  end

  config.after :each do
    DatabaseCleaner.clean
  end

  config.after(:suite) do
    # TODO: purge uploaded files
  end
end
