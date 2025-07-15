class UserMailer < ApplicationMailer
  def welcome user
    @user = user
    mail to: user.email, subject: 'Welcome!'
  end

  def notification_new_task task, user
    @task = task
    @user = user

    return if @user.email.blank?

    mail to: @user.email, subject: 'New task assigned'
  end

  def email_verification_code(email, code)
    @code = code
    mail to: email, subject: 'Email verification code'
  end
end
