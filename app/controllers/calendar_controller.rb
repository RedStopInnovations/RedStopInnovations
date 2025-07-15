class CalendarController < ApplicationController
  include HasABusiness

  def index
    authorize! :read, :calendar
  end

  def search_appointment
    authorize! :search, Availability
    ahoy_track_once 'Use search appointments feature'
  end

  def map
    authorize! :read, :calendar
    ahoy_track_once 'Use availability map feature'
  end
end
