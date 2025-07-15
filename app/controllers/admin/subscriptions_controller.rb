module Admin
  class SubscriptionsController < BaseController
    before_action do
      authorize! :manage, Subscription
    end
    before_action :set_subscription, only: [
      :show, :edit, :update, :invoices, :payments, :update_settings
    ]

    def index
      @search_query = Subscription.ransack(params[:q].try(:to_unsafe_h))

      @subscriptions = @search_query.
                  result.
                  includes(:business, :subscription_plan).
                  order(id: :desc).
                  page(params[:page])
    end

    def show
      @admin_settings_form = Admin::SubscriptionSettingsForm.new(@subscription.admin_settings)
      @admin_settings_form.email = @subscription.email
    end

    def invoices
      @subscription_invoices = BusinessInvoice.where(
        business_id: @subscription.business_id
        ).
        order(id: :desc).
        page(params[:page])
    end

    def payments
      @subscription_payments = SubscriptionPayment.where(
        business_id: @subscription.business_id
        ).
        order(id: :desc).
        page(params[:page])
    end

    def update
      if @subscription.update(update_subscription_params)
        redirect_to admin_subscription_url(@subscription),
                    notice: 'The subscription has been successfully updated.'
      else
        flash.now[:alert] = 'Failed to update subscription. Please check for form errors.'
        render :edit
      end
    end

    def update_settings
      @admin_settings_form = Admin::SubscriptionSettingsForm.new(params.require(:settings).permit(
        :email, :auto_send_invoice, :auto_payment, :auto_payment_delay, :notify_new_invoice
      ))

      @success = false
      @error = nil

      if @admin_settings_form.valid?
        @subscription.email = @admin_settings_form.email
        @subscription.admin_settings = @admin_settings_form.attributes.slice(
          *%i(auto_send_invoice auto_payment auto_payment_delay notify_new_invoice)
        )
        @subscription.save!
        @success = true
      else
        @success = false
        @error = "Validation error: #{@admin_settings_form.errors.full_messages.first}"
      end
    end

    private

    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    def update_subscription_params
      params.require(:subscription).permit(:subscription_plan_id)
    end
  end
end
