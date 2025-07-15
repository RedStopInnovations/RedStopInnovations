class CommunicationMailer < ApplicationMailer
  def communication(communication)
    @communication = communication
    @patient = communication.recipient

    mail(business_email_options(@communication.business).merge(
      subject: "You have a message from practitioner",
      to: @patient.email
    ))
  end

  def sms_received_notification(incoming_message)
    @incoming_message = incoming_message
    @patient = incoming_message.patient
    @business = @patient.business
    mail(
      subject: 'You have a message from patient',
      to: @business.email
    )
  end
end
