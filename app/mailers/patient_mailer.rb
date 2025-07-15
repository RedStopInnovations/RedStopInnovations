class PatientMailer < ApplicationMailer
  helper :application

  def new_patient_confirmation(patient)
    @patient = patient
    business = patient.business

    com_template = business.get_communication_template(CommunicationTemplate::TEMPLATE_ID_NEW_PATIENT_CONFIRMATION)

    com_template_renderred = Letter::Renderer.new(patient, com_template).
      render([
        patient,
        business
      ])

    com_template.attachments.each do |template_atm|
      attachments[template_atm.attachment_file_name] =
        Paperclip.io_adapters.for(template_atm.attachment).read
    end

    # Create communication
    com = business.communications.create!(
      message_type: Communication::TYPE_EMAIL,
      category: 'new_patient_confirmation',
      linked_patient_id: patient.id,
      recipient: patient,
      message: com_template_renderred.content,
    )

    CommunicationDelivery.create!(
      communication_id: com.id,
      recipient: patient.email,
      tracking_id: SecureRandom.base58(32),
      last_tried_at: Time.current,
      status: CommunicationDelivery::STATUS_SCHEDULED,
      provider_id: CommunicationDelivery::PROVIDER_ID_SENDGRID
    )

    @email_body = com_template_renderred.content

    mail(business_email_options(business).merge(
      to: patient.email,
      subject: com_template.email_subject
    ))
  end

  def treatment_note(treatment, options = {})
    @treatment = treatment
    @patient = treatment.patient
    @business = @patient.business

    attachments["treatment_note.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "Treatment Note",
          template: 'pdfs/treatments/show',
          locals: {
            treatment: @treatment,
            patient: @patient,
            business: @business
          }
        )
      )

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(business_email_options(@business).merge(
      to: @patient.email,
      subject: "Treatment Note",
      cc: @treatment.author&.email
    ))
  end

  def send_treatment_note_to_contact(treatment, contact, message, options = {})
    @message = message
    @contact = contact
    @treatment = treatment
    @patient = treatment.patient
    @business = @patient.business

    attachments["treatment_note.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "Treatment Note",
          template: 'pdfs/treatments/show',
          locals: {
            treatment: @treatment,
            patient: @patient,
            business: @business
          }
        )
      )

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(business_email_options(@business).merge(
      to: contact.email,
      subject: "Treatment Note",
      cc: @treatment.author&.email
    ))
  end

  def send_treatment_note_to_email(treatment, email, message)
    @message = message
    @treatment = treatment
    @patient = treatment.patient
    @business = @patient.business

    attachments["treatment_note.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "Treatment Note",
          template: 'pdfs/treatments/show',
          locals: {
            treatment: @treatment,
            patient: @patient,
            business: @business
          }
        )
      )

    mail(business_email_options(@business).merge(
      to: email,
      subject: "Treatment Note"
    ))
  end

  def send_multiple_treatment_notes_to_patient(patient, treatment_notes, options = {})
    @patient = patient
    @business = @patient.business

    attachments["treatment_note.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "Treatment Note",
          template: 'pdfs/treatments/multiple',
          locals: {
            treatment_notes: treatment_notes,
            patient: @patient,
            business: @business
          }
        )
      )

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(business_email_options(@business).merge(
      to: @patient.email,
      subject: "Treatment Note"
    ))
  end

  def send_multiple_treatment_notes_to_contact(patient, treatment_notes, contact, message, options = {})
    @message = message
    @contact = contact
    @patient = patient
    @business = @patient.business

    attachments["treatment_note.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "Treatment Note",
          template: 'pdfs/treatments/multiple',
          locals: {
            treatment_notes: treatment_notes,
            patient: @patient,
            business: @business
          }
        )
      )

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(business_email_options(@business).merge(
      to: contact.email,
      subject: "Treatment Note"
    ))
  end

  def send_multiple_treatment_notes_to_email(patient, treatment_notes, email, message)
    @message = message
    @patient = patient
    @business = @patient.business

    attachments["treatment_note.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "Treatment Note",
          template: 'pdfs/treatments/multiple',
          locals: {
            treatment_notes: treatment_notes,
            patient: @patient,
            business: @business
          }
        )
      )

    mail(business_email_options(@business).merge(
      to: email,
      subject: "Treatment Note"
    ))
  end
end
