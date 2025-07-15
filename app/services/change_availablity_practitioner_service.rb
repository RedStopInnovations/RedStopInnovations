class ChangeAvailablityPractitionerService
  attr_reader :availability, :form_request
  def call(availability, form_request)
    @availability = availability
    @form_request = form_request

    result = OpenStruct.new
    begin
      Availability.transaction do
        apply_availabilities = [availability]

        if apply_to_future_repeats? && availability.recurring?
          apply_availabilities += fetch_future_repeats(availability)
        end

        apply_availabilities.each do |avail|
          update_practitioner(avail)

          # Grant patient accesses
          avail.appointments.map(&:patient_id).each do |patient_id|
            unless PatientAccess.exists?(
                    user_id: target_practitioner.user_id, patient_id: patient_id
                  )
              PatientAccess.create!(
                user_id: target_practitioner.user_id, patient_id: patient_id
              )
            end
          end
        end

        result.success = true
        availability.reload
        result.availability = availability
      end

      if target_practitioner&.user&.google_calendar_sync_setting&.status_active?
        SyncAvailabilityToGoogleCalendarWorker.perform_async(@availability.id)
        if apply_to_future_repeats? && availability.recurring?
          Availability.where(
              recurring_id: avail.recurring_id,
              practitioner_id: avail.practitioner_id
            ).
            where('id <> ?', avail.id).
            where('start_time > ?', avail.start_time).
            pluck(:id).
            each do |repeat_avail_id|
              SyncAvailabilityToGoogleCalendarWorker.perform_async(repeat_avail_id)
            end
        end
      end
    rescue => e
      Sentry.capture_exception(e)
      result.success = false
    end
    result
  end

  private

  def apply_to_future_repeats?
    form_request.apply_to_future_repeats
  end

  def fetch_future_repeats(avail)
    Availability.where(
      recurring_id: avail.recurring_id,
      practitioner_id: avail.practitioner_id
    ).
    includes(:practitioner, :appointments).
    where('id <> ?', avail.id).
    where('start_time > ?', avail.start_time).
    to_a
  end

  def target_practitioner
    @target_practitioner ||= Practitioner.find(form_request.practitioner_id)
  end

  def update_practitioner(avail)
    update_attributes = {
      practitioner_id: target_practitioner.id
    }

    # Need to clear the recurring to avoid conflict with the previous practitioner
    if avail.recurring?
      update_attributes[:recurring_id] = nil
    end

    avail.assign_attributes update_attributes
    avail.save!(validate: false)

    Appointment.
      with_deleted.
      where(availability_id: avail.id).
      update_all(
        practitioner_id: target_practitioner.id
      )
  end
end
