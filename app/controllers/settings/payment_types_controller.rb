module Settings
  class PaymentTypesController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    def index
      if current_business.payment_types.count == 0
        generate_default_payment_types
      end

      @payment_types = current_business.payment_types
    end

    def edit
      @payment_type = current_business.payment_types.find(params[:id])
    end

    def update
      @payment_type = current_business.payment_types.find(params[:id])

      if @payment_type.update(update_params)
        redirect_to settings_payment_types_path,
                    notice: 'Payment type has been successfully updated.'
      else
        render :edit
      end
    end

    private

    def update_params
      []
    end

    def generate_default_payment_types
      PaymentType::TYPES.each do |type|
        current_business.payment_types.create!(
          name: type,
          type: type
        )
      end
    end
  end
end
