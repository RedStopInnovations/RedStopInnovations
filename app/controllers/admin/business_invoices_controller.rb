module Admin
  class BusinessInvoicesController < BaseController

    before_action do
      authorize! :manage, BusinessInvoice
    end

    before_action :set_business_invoice, only: [
      :show, :edit, :update, :charge, :destroy, :deliver,
      :billed_items, :delete_billed_item,
      :reset_items
    ]

    def index
      @search_query = BusinessInvoice.not_deleted.ransack(params[:q].try(:to_unsafe_h))

      @business_invoices = @search_query.
                  result.
                  includes(:business).
                  order(id: :desc).
                  page(params[:page])
    end

    def edit
    end

    def update
      if @business_invoice.update(business_invoice_params)
        redirect_to admin_business_invoice_path(@business_invoice),
                    notice: 'The invoice was successfully updated.'
      else
        render :edit
      end
    end

    def show
      @payments = @business_invoice.subscription_payments
      respond_to do |format|
        format.html
        format.pdf do
          render(
            pdf: "Subscription invoice #{@business_invoice.id}",
            template: 'pdfs/business_invoice',
            locals: {
              business_invoice: @business_invoice
            }
          )
        end
        format.pdf do
          @business = @business_invoice.business
          render pdf: "business-invoice-#{@business_invoice.id}",
                 template: 'pdfs/business_invoice',
                 locals: {
                   business_invoice: @business_invoice
                 }
        end
      end
    end

    def charge
      begin
        result = SubscriptionInvoicePaymentService.new.call(@business_invoice)
        if result.success
          flash[:notice] = "Payment has been successfully made."
        else
          flash[:alert] = "An error has occurred. Unable to process payment."
        end
      rescue => e
        case e
        when SubscriptionInvoicePaymentService::InvoiceNotPayableError
          flash[:alert] = "The invoice is not payable. Error: #{ e.message }"
        when SubscriptionInvoicePaymentService::PaymentProcessError
          flash[:alert] = "An error has occurred while charge the card: #{e.message}"
          unless e.is_a?(Stripe::CardError)
            Sentry.capture_exception(e)
          end
        else
          flash[:alert] = "An server error has occurred: #{e.message}"
          Sentry.capture_exception(e)
        end
      end

      redirect_back fallback_location: admin_business_invoice_path(@business_invoice)
    end

    def billed_items
      @subscription_billings = SubscriptionBilling.where(
          business_invoice_id: @business_invoice.id
        )
        .includes(:appointment)
        .order(created_at: :asc)
        .page(params[:page])
        .per(50)
    end

    # def edit_billed_item
    #   @billed_item = SubscriptionBilling.find(params[:item_id])
    # end

    # def update_billed_item
    #   @billed_item = SubscriptionBilling.find(params[:item_id])
    #   @billed_item.update(
    #       params.require(:subscription_billing).permit(:subscription_price_on_date)
    #     )
    # end

    def delete_billed_item
      @billed_item = SubscriptionBilling.find(params[:item_id])
      @billed_item.destroy
      @billed_items = SubscriptionBilling.where(
          business_invoice_id: @business_invoice.id
        )
    end

    def deliver
      BusinessInvoiceMailer.business_invoice_mail(
        @business_invoice,
        @business_invoice.business.subscription
      ).deliver_later
      @business_invoice.update_column :last_sent_at, Time.current
      flash[:notice] = 'The invoice has been successfully sent.'
      redirect_back fallback_location: admin_business_invoice_path(@business_invoice)
    end

    def destroy
      @business_invoice.update_column(:deleted_at, Time.current)
      redirect_to admin_business_invoices_url,
                  notice: 'The invoice was successfully deleted.'
    end

    def reset_items
      ActiveRecord::Base.transaction do
        @business_invoice.items.delete_all
        @business_invoice.items_attributes =
          SubscriptionBillingService.new.build_invoice_items(
            SubscriptionBilling.where(
              business_invoice_id: @business_invoice.id
            )
          )
        @business_invoice.save!
      end
      redirect_to admin_business_invoice_path(@business_invoice),
                  notice: 'The invoice was successfully updated.'
    end

    private

    def set_business_invoice
      @business_invoice = BusinessInvoice.find(params[:id])
    end

    def business_invoice_params
      params.require(:business_invoice).permit(
        :discount,
        :notes,
        :payment_status,
        :date_closed,
        items_attributes: [
          :id,
          :unit_name,
          :quantity,
          :unit_price,
          :_destroy
        ]
      )
    end
  end
end
