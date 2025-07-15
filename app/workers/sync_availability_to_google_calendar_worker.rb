class SyncAvailabilityToGoogleCalendarWorker
  include Sidekiq::Worker
  sidekiq_options retry: 3

  # @param Integer availability_id
  def perform(availability_id)
    SyncAvailabilityGoogleCalendarService.new.call(availability_id)
  end
end