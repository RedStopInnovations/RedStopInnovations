class AdminMailer < ApplicationMailer
  def new_user user
    @user = user
    @practitioner = user.practitioner
    mail to: 'admin@example.com', subject: 'New user sign up !'
  end

  def new_referral(referral)
    @referral = referral
    mail to: 'admin@example.com', subject: 'New referral received'
  end

  def new_subscription_invoice(invoice)
    @invoice = invoice
    @business = @invoice.business
    mail to: 'admin@example.com', subject: 'New subscription invoice issued'
  end

  def business_suspended_confirmation(business)
    @business = business
    mail to: 'admin@example.com', subject: 'Business account suspended confirmation'
  end

  def business_unsuspended_confirmation(business)
    @business = business
    mail to: 'admin@example.com', subject: 'Business account unsuspended confirmation'
  end
end
