class SubscriptionMailer < ApplicationMailer
  def trial_ending_notification(subscription)
    @subscription = subscription
    @business = subscription.business

    recepient_email = @business.accounting_email.presence || @business.email.presence || @business.users.role_administrator.order(id: :asc).first.try(:email)

    @remaining_trial_days = subscription.remaining_trial_days

    mail(
      subject: "Your have #{@remaining_trial_days} days left of your free trial",
      to: recepient_email
    )
  end
end
