class EmergencyMailer < ApplicationMailer
  def notify_practitioner emergency, practitioner, count
    @emergency = emergency
    @practitioner = practitioner
    @count = count

    mail to: @practitioner.email, subject: "#{@emergency.profession} emergency service request"
  end
end
