module Admin
  class SubscriptionPaymentsController < BaseController
    before_action do
      authorize! :manage, Subscription
    end
    before_action :find_payment, only: [:show, :edit, :update, :destroy]

    def index
      @subscription_payments = SubscriptionPayment
        .includes(:business, :business_invoice)
        .order(id: :desc)
        .page(params[:page])
    end

    def show; end

    def new
      @subscription_payment = SubscriptionPayment.new
      if params[:invoice_id].present?
        @subscription_payment.invoice_id = BusinessInvoice.find(params[:invoice_id]).id
      end
    end

    def create
      @subscription_payment = SubscriptionPayment.new(create_params)
      if @subscription_payment.invoice_id?
        @invoice = BusinessInvoice.find(@subscription_payment.invoice_id)
        @subscription_payment.business_id = @invoice.business_id
      end
      if @subscription_payment.save
        redirect_to admin_subscription_payment_url(@subscription_payment),
                    notice: 'The payment has been successfully added.'
      else
        flash.now[:alert] = 'Could not save payment. Please check for form errors.'
        render :new
      end
    end

    def edit
      unless @subscription_payment.editable?
        redirect_to admin_subscription_payment_url(@subscription_payment),
                    alert: "#{@subscription_payment.payment_type} payment is not editable."
      end
    end

    def update
      unless @subscription_payment.editable?
        redirect_to admin_subscription_payment_url(@subscription_payment),
                    alert: "#{@subscription_payment.payment_type} payment is not editable."
      end

      if @subscription_payment.update(update_params)
        redirect_to admin_subscription_payment_url(@subscription_payment),
                    notice: 'The payment has been successfully updated.'
      else
        flash.now[:alert] = 'Could not update payment. Please check for form errors.'
        render :edit
      end
    end

    def destroy
      @subscription_payment.destroy
      redirect_to admin_subscription_payments_url,
                  notice: 'The payment has been successfully deleted.'
    end

    private

    def find_payment
      @subscription_payment = SubscriptionPayment.find(params[:id])
    end

    def create_params
      params.require(:subscription_payment).permit(
        :invoice_id, :payment_date, :payment_type, :amount
      )
    end

    def update_params
      params.require(:subscription_payment).permit(
        :payment_date, :payment_type, :amount
      )
    end
  end
end
