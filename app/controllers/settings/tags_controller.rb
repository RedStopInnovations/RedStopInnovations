module Settings
  class TagsController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, :settings
    end

    before_action :find_tag, only: [:edit, :update, :destroy]

    def index
      @tags = current_business.tags.all
    end

    def new
      @tag = Tag.new
    end

    def create
      @tag = current_business.tags.new(tag_params)
      @tag.tag_type = Tag::TYPE_PATIENT  # Fixed to Patient util extend to other types

      if @tag.save
        redirect_to settings_tags_url,
                      notice: 'The tag has been successfully created.'
      else
        flash.now[:alert] = 'Failed to create tag. Please check for form errors.'
        render :new
      end
    end

    def edit
    end

    def update
      if @tag.update(tag_params)
        redirect_to settings_tags_url,
                      notice: 'The tag has been successfully updated.'
      else
        flash.now[:alert] = 'Failed to update tag. Please check for form errors.'
        render :edit
      end
    end

    def destroy
      @tag.destroy
      redirect_to settings_tags_url,
                  notice: 'The tag has been successfully deleted.'
    end

    private

    def tag_params
      params.require(:tag).permit(:name, :color)
    end

    def find_tag
      @tag = current_business.tags.find(params[:id])
    end
  end
end