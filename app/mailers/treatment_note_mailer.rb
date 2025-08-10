class TreatmentNoteMailer < ApplicationMailer
  helper :application

  def treatment_note_mail(treatment_note, recipient_email, email_subject, email_content, options = {})
    @email_content = email_content
    treatment_note = treatment_note
    patient = treatment_note.patient
    business = patient.business

    attachments["treatment_note_#{treatment_note.id}.pdf"] =
      WickedPdf.new.pdf_from_string(
        render_to_string(
          pdf: "Treatment note #{treatment_note.id}",
          template: 'pdfs/treatment_notes/single',
          locals: {
            treatment: treatment_note,
            patient: patient,
            business: business
          }
        )
      )

    if options[:sendgrid_delivery_tracking_id].present?
      add_sendgrid_delivery_tracking_header options[:sendgrid_delivery_tracking_id]
    end

    mail(business_email_options(business).merge(
      to: recipient_email,
      subject: email_subject,
    ))
  end
end