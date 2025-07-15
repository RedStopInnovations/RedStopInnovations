class SendReviewRequestService
  class Exception < StandardError; end

  def call(appointment, force = false)
    patient = appointment.patient

    if appointment.end_time.future?
      raise Exception, 'The appointment is not yet completed.'
    end

    if Review.exists?(practitioner_id: appointment.practitioner_id, patient_id: appointment.patient_id)
      raise Exception, 'The client has already given a review to the practitioner'
    else
      if patient.email?
        ReviewMailer.review_request_mail(appointment).deliver_later
      else
        raise Exception, 'The client has no email address'
      end
    end
  end
end