class DeleteAppointmentService
  attr_reader :business, :appointment

  def call(business, appointment, author)
    @appointment = appointment

    appointment.destroy_by_author(author)
    avail = appointment.availability

    if avail.home_visit? || avail.facility?
      avail.refresh_appointments_order
    end

    if avail.home_visit?
      HomeVisitRouting::ArrivalCalculate.new.call(avail.id)
      if appointment.practitioner&.user&.google_calendar_sync_setting&.status_active?
        SyncAvailabilityToGoogleCalendarWorker.perform_async(appointment.availability_id)
      end
    elsif avail.facility?
      HomeVisitRouting::FacilityArrivalCalculate.new.call(avail.id)
    end

    AvailabilityCachedStats.new.update(avail)

    if appointment.start_time.future?
      SendAppointmentNotificationJob.perform_later(appointment.id, NotificationType::APPOINTMENT__CANCELLED)
    end
  end
end
