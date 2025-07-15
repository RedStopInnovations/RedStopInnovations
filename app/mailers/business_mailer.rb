class BusinessMailer < ApplicationMailer
  def new_referral(referral, business)
    @referral = referral
    @business = business
    mail to: @business.email, subject: 'New referral submitted'
  end

  def bank_account_details_updated(business, author, timestamp)
    @business = business
    @author = author
    @change_at = Time.at(timestamp)

    recipients = [@business.email]
    recipients.concat business.users.role_administrator.pluck(:email)
    recipients.uniq!

    mail to: @business.email, cc: recipients, subject: 'Bank details updated confirmation'
  end
end
