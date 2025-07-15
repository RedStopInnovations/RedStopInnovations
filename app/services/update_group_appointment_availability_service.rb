class UpdateGroupAppointmentAvailabilityService
  attr_reader :availability, :original_availability, :form_request

  # @param ::Availability availability
  # @param CreateGroupAppointmentAvailabilityForm form_request
  def call(availability, form_request)
    @availability = availability
    @original_availability = availability.dup
    @form_request = form_request

    Availability.transaction do
      update_availability

      appointments_attrs_to_update = {}
      if availability_time_changed?
        appointments_attrs_to_update[:start_time] = availability.start_time
        appointments_attrs_to_update[:end_time] = availability.end_time
      end

      if group_appointment_type_changed?
        appointments_attrs_to_update[:appointment_type_id] = availability.group_appointment_type_id
      end

      if appointments_attrs_to_update.present?
        Appointment.where(availability_id: availability.id).
          with_deleted.
          each do |appt|
            appt.update(appointments_attrs_to_update)
          end
      end

      if availability_time_changed?
        HomeVisitRouting::GroupAppointmentArrivalCalculate.new.call(availability.id)
      end

      AvailabilityCachedStats.new.update availability
    end

    if availability.practitioner&.user&.google_calendar_sync_setting&.status_active?
      SyncAvailabilityToGoogleCalendarWorker.perform_async(availability.id)
    end
  end

  private

  def availability_time_changed?
    (original_availability.start_time != availability.start_time) ||
      (original_availability.end_time != availability.end_time)
  end

  def group_appointment_type_changed?
    original_availability.group_appointment_type_id != availability.group_appointment_type_id
  end

  def update_availability
    availability.assign_attributes(form_request.attributes.slice(
      :start_time,
      :end_time,
      :max_appointment,
      :address1,
      :city,
      :state,
      :postcode,
      :country
    ))

    availability.description = form_request.description.presence

    availability.assign_attributes(
      group_appointment_type_id: form_request.group_appointment_type_id,
      contact_id: form_request.contact_id.presence
    )

    availability.save!(validate: false)
  end
end
