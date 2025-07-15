class OutcomeMeasureMailer < ApplicationMailer
  def send_to_patient(outcome_measure)
    @outcome_measure = outcome_measure
    @patient = outcome_measure.patient
    @practitioner = outcome_measure.practitioner
    @business = @practitioner.business

    return false if @patient&.email.blank?

    mail(business_email_options(@business).merge(
      to: @patient.email,
      subject: "#{outcome_measure.outcome_measure_type.name} - #{@business.name}"
    ))
  end
end
