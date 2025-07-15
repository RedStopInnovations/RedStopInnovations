class DeleteAvailabilityService
  attr_accessor :availability, :author, :form_request

  def call(availability, form_request, author)
    @author = author
    @availability = availability
    @form_request = form_request

    deleted_repeat_ids = []

    now = Time.current

    ActiveRecord::Base.transaction do
      # @TODO: review this! User might delete repeat availability that had scheduled appointments without awareness
      if @availability.recurring? && form_request.delete_future_repeats?
        deleted_repeat_ids = delete_future_repeats
      end

      Appointment.
        where(availability_id: @availability.id).
        each do |appt|
        appt.destroy_by_author(author)
      end

      if form_request.notify_cancel_appointment
        cancel_appoinment_ids = @availability.appointments.where(
          'start_time > ?', now
        ).pluck(:id)

        cancel_appoinment_ids.each do |appt_id|
          # AppointmentMailer.cancel_notification(appt_id).deliver_later
        end
      end

      @availability.delete
    end

    if @availability.practitioner&.user&.google_calendar_sync_setting&.status_active?
      if @availability.home_visit? || @availability.non_billable? || @availability.group_appointment?
        SyncAvailabilityDeletionToGoogleCalendarWorker.perform_async(@availability.id)

        if @availability.recurring? && form_request.delete_future_repeats?
          deleted_repeat_ids.each do |repeat_avail_id|
            SyncAvailabilityDeletionToGoogleCalendarWorker.perform_async(repeat_avail_id)
          end
        end
      end
    end
  end

  private

  def delete_future_repeats
    delete_repeat_ids = Availability.where(recurring_id: @availability.recurring_id).
      where(practitioner_id: @availability.practitioner_id).
      where('start_time > ?', @availability.start_time).
      pluck(:id)

    now = Time.current

    if delete_repeat_ids.present?
      Availability.where(id: delete_repeat_ids).delete_all

      # Delete appoinments
      delete_appt_ids = Appointment.where(availability_id: delete_repeat_ids).pluck(:id)

      if delete_appt_ids.present?
        Appointment.where(id: delete_appt_ids).each do |appt|
          appt.destroy_by_author(author)
        end
      end

      if @form_request.notify_cancel_appointment
        cancel_appoinment_ids = Appointment.where(availability_id: delete_repeat_ids).
          where('start_time > ?', Time.current).
          pluck(:id)

        if cancel_appoinment_ids.present?
          cancel_appoinment_ids.each do |appt_id|
            # AppointmentMailer.cancel_notification(appt_id).deliver_later
          end
        end
      end

    end

    delete_repeat_ids
  end
end
