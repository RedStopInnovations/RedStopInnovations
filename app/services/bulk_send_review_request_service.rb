class BulkSendReviewRequestService
  class Exception < StandardError; end

  def call(business, appointment_ids)
    appointments = business.appointments.where(id: appointment_ids)

    sent_practitioner_ids = []

    appointments.each do |appointment|
      patient = appointment.patient

      if patient.email? &&
        appointment.end_time.past? &&
        !Review.exists?(practitioner_id: appointment.practitioner_id, patient_id: patient.id) &&
        sent_practitioner_ids.include?(appointment.practitioner_id)

        ReviewMailer.review_request_mail(appointment).deliver_later
        sent_practitioner_ids << appointment.practitioner_id
      end
    end
  end
end