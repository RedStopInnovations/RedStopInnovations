module Settings
  class SubscriptionsController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    def index
      @subscription = current_business.subscription
    end

    def add_card_details
      # TODO:
      #   - catch errors
      #   - Update card for existing customer instead of create new
      #
      return if params[:stripeToken].nil?

      stripe_customer = Stripe::Customer.create(
        name: current_business.name,
        email: params[:stripeEmail] || current_business.email.presence,
        source: params[:stripeToken],
        metadata: {
          business_id: current_business.id,
          business_name: current_business.name,
          business_email: current_business.email.presence,
          business_phone: current_business.phone.presence
        }
      )
      subscription = current_business.subscription
      subscription.stripe_customer_id = stripe_customer.id
      subscription.card_last4 = stripe_customer.sources.data[0].last4
      subscription.save!

      redirect_to settings_subscriptions_path, notice: 'Card added successfully!'
    end

    def invoices
      @subscription_invoices = BusinessInvoice.where(
          business_id: current_business.id
        ).
        not_deleted.
        order(id: :desc).
        page(params[:page])
    end

    def payments
      @subscription_payments = SubscriptionPayment.where(
        business_id: current_business.id
        ).
        order(id: :desc).
        page(params[:page])
    end

  end
end
