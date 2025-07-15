module Admin
  class SubscriptionDiscountsController < BaseController
    before_action do
      authorize! :manage, SubscriptionDiscount
    end

    before_action :set_subscription_discount, only: [:show, :edit, :update, :destroy]

    def index
      @subscription_discounts = SubscriptionDiscount.page(params[:page])
    end

    def show

    end

    def new
      @subscription_discount = SubscriptionDiscount.new
    end

    def create
      @subscription_discount = SubscriptionDiscount.new(subscription_discount_params)

      if @subscription_discount.save
        redirect_to admin_subscription_discount_url(@subscription_discount), notice: 'Subscription Discount was successfully created.'
      else
        render :new
      end
    end

    def edit

    end

    def update
      if @subscription_discount.update(business_params)
        redirect_to admin_subscription_discount_url(@subscription_discount), notice: 'Subscription Discount was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @subscription_discount.destroy
      respond_to do |format|
        format.html { redirect_to admin_subscription_discounts_url, notice: 'Subscription Discount was successfully deleted.'}
        format.json { head :no_content }
      end
    end

    private

    def set_subscription_discount
      @subscription_discount = SubscriptionDiscount.find(params[:id])
    end

    def subscription_discount_params
      params.require(:subscription_discount).permit(
        :name,
        :discount_type,
        :business_id,
        :amount,
        :from_date,
        :end_date,
        :expired
      )
    end



  end
end
