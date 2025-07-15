module Settings
  class TriggerCategoriesController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    before_action :find_category, only: [:show, :edit, :update, :destroy]

    def index
      ahoy_track_once 'View trigger categories settings'

      @trigger_categories = current_business.trigger_categories.page
    end

    def show
    end

    def new
      @trigger_category = TriggerCategory.new
      @trigger_category.words.build
    end

    def create
      @trigger_category = current_business.trigger_categories.new trigger_category_params

      if @trigger_category.save
        redirect_to settings_trigger_category_url(@trigger_category),
                    notice: 'The category has been created successfully.'
      else
        flash.now[:alert] = 'Failed to create category. Please check for form errors.'
        render :new
      end
    end

    def edit
    end

    def update
      if @trigger_category.update(trigger_category_params)
        redirect_to settings_trigger_category_url(@trigger_category),
                    notice: 'The category has been update successfully.'
      else
        flash.now[:alert] = 'Failed to update category. Please check for form errors.'
        render :edit
      end
    end

    def destroy
      @trigger_category.destroy
      redirect_to settings_trigger_categories_url,
                  notice: 'The trigger category has been deleted.'
    end

    private

    def trigger_category_params
      params.require(:trigger_category).permit(
        :name,
        words_attributes: [:id, :text, :_destroy]
      )
    end

    def find_category
      @trigger_category = current_business.trigger_categories.find(params[:id])
    end
  end
end
