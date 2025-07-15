class ReferralMailer < ApplicationMailer
  def referral_confirmation(referral)
    @referral = referral
    @business = referral.business

    if @business
      mail(business_email_options(@business).merge(
        to: @referral.referrer_email, subject: 'Referral confirmation'
      ))
    else
      mail(
        to: @referral.referrer_email, subject: 'Referral confirmation'
      )
    end
  end
end
