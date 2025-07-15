class AppointmentReminderMailer < ApplicationMailer
  def first_notification(appointment_id, options = {})
    @appointment  = Appointment.find appointment_id
    @practitioner = @appointment.practitioner
    @patient  = @appointment.patient
    @business = @practitioner.business
    @template = @business.get_communication_template('appointment_reminder')

    @template.attachments.each do |template_atm|
      attachments[template_atm.attachment_file_name] =
        Paperclip.io_adapters.for(template_atm.attachment).read
    end

    @content = Letter::Renderer.new(@patient, @template).
      render([
        @appointment,
        @patient,
        @practitioner,
        @business
      ]).content

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(business_email_options(@business).merge(
      to: @patient.email,
      subject: @template.email_subject.presence || "Appointment reminder"
    ))
  end

  def patient_follow_up(appointment_id)
    @appointment  = Appointment.find appointment_id
    @practitioner = @appointment.practitioner
    @patient  = @appointment.patient
    @business = @practitioner.business
    @template = @business.get_communication_template('patient_followup')
    @content  = Letter::Renderer.new(@patient, @template).
      render([
        @appointment,
        @patient,
        @practitioner,
        @business
      ])
    @template.attachments.each do |template_atm|
      attachments[template_atm.attachment_file_name] =
        Paperclip.io_adapters.for(template_atm.attachment).read
    end
    return false if @appointment.patient&.email.blank?

    mail(business_email_options(@business).merge(
      to: @appointment.patient.email,
      subject: "We miss you"
    ))
  end

  def daily_appointments_schedule(practitioner, appointments)
    @practitioner = practitioner
    @business = practitioner.business
    @appointments = appointments
    @date = appointments.first.start_time_in_practitioner_timezone.to_date

    attachments["daily_appointments_schedule_#{@date.strftime('%Y%m%d')}.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          template: 'pdfs/daily_appointments_schedule',
          locals: {
            business: @business,
            practitioner: @practitioner,
            date: @date,
            appointments: appointments
          }
        )
      )

    mail(business_email_options(@business).merge(
      to: @practitioner.user_email,
      subject: "Daily Appointment Schedule for #{@date.strftime('%a %d %B')}"
    ))
  end
end
