class PractitionerMailer < ApplicationMailer
  helper :money

  def new_referral(referral, practitioner)
    @referral = referral
    @practitioner = practitioner
    mail to: practitioner.user_email,
         subject: 'New referral',
         cc: practitioner.business.email
  end

  def new_online_booking(appointment)
    @appointment = appointment
    @practitioner = appointment.practitioner
    @business = @practitioner.business

    mail to: @practitioner.email, subject: 'New appointment booked online',
         cc: @business.email
  end

  def performance_report_mail(practitioner, start_date, end_date, performance_data)
    @practitioner = practitioner
    @business = practitioner.business
    @start_date = start_date
    @end_date = end_date
    @performance_data = performance_data

    mail to: practitioner.user_email,
         subject: 'Performance report'
  end
end
