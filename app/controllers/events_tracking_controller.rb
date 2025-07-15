# Track events(user behaviours)
class EventsTrackingController < ApplicationController
  def save
    encoded_event_info = params[:event].to_s.presence
    if encoded_event_info
      begin
        # OPTIMIZE: run in background
        decoded_raw_info = Base64.decode64 encoded_event_info
        event_raw_info = JSON.parse decoded_raw_info, symbolize_names: true
        EventsTrackingService.new.call(request, event_raw_info)
      rescue => e
        raise e if Rails.env.development?
      end
    end

    render json: { success: true }
  end
end
