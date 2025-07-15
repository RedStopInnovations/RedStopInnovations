class PatientLetterMailer < ApplicationMailer
  def email_letter(patient_letter, sender, email_subject = nil, options = {})
    @patient_letter = patient_letter
    @patient = patient_letter.patient
    subject = email_subject.presence || @patient_letter.email_subject

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(letter_email_options(sender).merge(
      to: @patient.email,
      subject: subject
    ))
  end

  def attachment_letter(patient_letter, sender, email_subject = nil, email_content = nil, options = {})
    @patient_letter = patient_letter
    @patient = patient_letter.patient
    @email_content = email_content

    subject = email_subject.presence || @patient_letter.email_subject

    attachments["#{@patient_letter.description.parameterize}.pdf"] =
     WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: @patient_letter.description.parameterize,
          template: 'pdfs/patient_letter',
          locals: {
            patient_letter: @patient_letter
          }
        )
      )

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(letter_email_options(sender).merge(
      to: @patient.email,
      subject: subject
    ))
  end

  # @TODO: too many params
  def send_as_email_to_email(patient_letter, sender, email, email_subject = nil, options = {})
    @patient_letter = patient_letter
    @patient = patient_letter.patient
    subject = email_subject.presence || @patient_letter.email_subject

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(letter_email_options(sender).merge(
      to: email,
      subject: subject
    ))
  end

  # @TODO: too many params
  def send_as_attachment_to_email(patient_letter, sender, email, email_subject = nil, email_content = nil, options = {})
    @patient_letter = patient_letter
    @patient = patient_letter.patient
    subject = email_subject.presence || @patient_letter.email_subject
    @email_content = email_content

    attachments["#{@patient_letter.description.parameterize}.pdf"] =
     WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: @patient_letter.description.parameterize,
          template: 'pdfs/patient_letter',
          locals: {
            patient_letter: @patient_letter
          }
        )
      )

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(letter_email_options(sender).merge(
      to: email,
      subject: subject
    ))
  end

  private

  def letter_email_options(sender)
    options = {}
    business = sender.business

    if sender.email?
      options[:reply_to] = sender.email
      options[:from] = "#{sender.full_name} <#{sender.email}>"
    elsif business.email?
      options[:reply_to] = business.email
      options[:from] = "#{business.name} <#{business.email}>"
    end

    options
  end
end
