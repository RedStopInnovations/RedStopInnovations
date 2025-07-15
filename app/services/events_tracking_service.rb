class EventsTrackingService
  DUPLICATE_THRESHOLD = 60 # Seconds

  attr_reader :request, :event_raw_info

  def call(request, event_raw_info)
    @request = request
    @event_raw_info = event_raw_info

    case event_raw_info.fetch(:type)
    when AppEvent::TYPE_RCI
      track_reveal_contact_info
    end
  end

  private

  def track_reveal_contact_info
    required_data_attrs = %i(
      business_id
      url
      page_title
      source_type
      source_id
      source_title
      contact_info_type
      contact_info_value
    )

    event_data = Hash[required_data_attrs.map {|x| [x, nil]}].merge(
      event_raw_info.fetch(:data)
    )

    # Save visitor IP address for later use
    event_data[:ip] = request.remote_ip
    # Stringify all data values
    event_data.transform_values!(&:to_s)

    # TODO: separate validations
    valid = event_data.all? { |key, val| val.present? }
    business_id = event_data[:business_id]

    valid = valid && Business.exists?(id: business_id)
    if valid
      is_duplicate = AppEvent.
        where(event_type: AppEvent::TYPE_RCI).
        where("data->>'business_id' = ?", business_id.to_s).
        where("data->>'source_type' = ?", event_data[:source_type]).
        where("data->>'contact_info_type' = ?", event_data[:contact_info_type]).
        where("data->>'source_id' = ?", event_data[:source_id]).
        where("data->>'ip' = ?", request.remote_ip).
        where('created_at >= ?', DUPLICATE_THRESHOLD.seconds.ago).
        exists?

      unless is_duplicate
        event = AppEvent.new(
          event_type: AppEvent::TYPE_RCI,
          data: event_data
        )
        event.save
      end
    end
  end
end
