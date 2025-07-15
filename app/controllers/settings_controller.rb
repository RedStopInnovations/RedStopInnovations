class SettingsController < ApplicationController
  include HasABusiness

  def index
    authorize! :read, :settings
  end
end