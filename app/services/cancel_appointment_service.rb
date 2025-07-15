class CancelAppointmentService
  attr_reader :business, :appointment

  def call(business, appointment, author = nil)
    @appointment = appointment

    appointment.update(
      cancelled_at: Time.current,
      cancelled_by_id: author.try(:id)
    )

    # @TODO: wrap in DB transaction?
    Availability.reset_counters appointment.availability_id, 'appointments_count'

    avail = appointment.availability

    if avail.home_visit? || avail.facility?
      avail.refresh_appointments_order
    end

    if avail.home_visit?
      HomeVisitRouting::ArrivalCalculate.new.call(avail.id)
    elsif avail.facility?
      HomeVisitRouting::FacilityArrivalCalculate.new.call(avail.id)
    end

    AvailabilityCachedStats.new.update avail

    if avail.home_visit?
      if appointment.practitioner&.user&.google_calendar_sync_setting&.status_active?
        SyncAvailabilityToGoogleCalendarWorker.perform_async(appointment.availability_id)
      end
    end

    if appointment.start_time.future?
      SendAppointmentNotificationJob.perform_later(appointment.id, NotificationType::APPOINTMENT__CANCELLED)
    end
  end
end
