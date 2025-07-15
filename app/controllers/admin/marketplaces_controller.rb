module Admin
  class MarketplacesController < BaseController

    before_action do
      authorize! :manage, ::Marketplace
    end

    before_action :find_marketplace, only: [:show, :edit, :update]

    def index
      @marketplaces = ::Marketplace.page(params[:page]).per(25)
    end

    def new
      @marketplace = ::Marketplace.new
    end

    def create
      create_params = marketplace_params
      business_ids = create_params.delete(:business_ids)
      business_ids ||= []
      business_ids.map!(&:to_i)
      @marketplace = ::Marketplace.new(create_params)

      if @marketplace.save
        if business_ids.present?
          Business.where(id: business_ids).update_all(marketplace_id: @marketplace.id)
        end
        redirect_to admin_marketplace_url(@marketplace),
                    notice: 'The marketplace has been successfully created.'
      else
        flash.now[:alert] = 'Please check for form errors.'
        render :new
      end
    end

    def show; end

    def edit; end

    def update
      update_params = marketplace_params
      update_business_ids = update_params.delete(:business_ids)

      update_business_ids ||= []
      update_business_ids.map!(&:to_i)

      if @marketplace.update(update_params)
        current_business_ids = @marketplace.business_ids
        if update_business_ids.present?
          Business.where(id: update_business_ids).update_all(
            marketplace_id: @marketplace.id
          )
        end

        unassign_business_ids = current_business_ids - update_business_ids

        if unassign_business_ids.present?
          Business.where(id: unassign_business_ids).update_all(
            marketplace_id: nil
          )
        end
        redirect_to admin_marketplace_url(@marketplace),
                    notice: 'The marketplace has been successfully updated.'
      else
        flash.now[:alert] = 'Please check for form errors.'
        render :edit
      end
    end

    private

    def find_marketplace
      @marketplace = ::Marketplace.find(params[:id])
    end

    def marketplace_params
      params.require(:marketplace).permit(:name, business_ids: [])
    end
  end
end
