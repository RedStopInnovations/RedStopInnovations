module Admin
  class TagsController < BaseController
    before_action do
      authorize! :manage, Tag
    end
    before_action :set_tag, only: [:show, :edit, :update, :destroy]

    def index
      @tags = Tag.page(params[:page])
    end

    def show
    end

    def new
      @tag = Tag.new
    end

    def edit
    end

    def create
      @tag = Tag.new(tag_params)

      respond_to do |format|
        if @tag.save
          format.html { redirect_to admin_tag_path(@tag), notice: 'Tag was successfully created.' }
          format.json { render :show, status: :created, location: @tag }
        else
          format.html { render :new }
          format.json { render json: @tag.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        if @tag.update(tag_params)
          format.html { redirect_to admin_tag_path(@tag), notice: 'Tag was successfully updated.' }
          format.json { render :show, status: :ok, location: @tag }
        else
          format.html { render :edit }
          format.json { render json: @tag.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      if @tag.practitioners.count > 0
        redirect_to admin_tags_url, alert: 'The tag is in-used. Could not be deleted.'
      else
        @tag.destroy
        redirect_to admin_tags_url, notice: 'Tag was successfully destroyed.'
      end
    end

    private

    def set_tag
      @tag = Tag.find(params[:id])
    end

    def tag_params
      params.require(:tag).permit(:name, :classification)
    end
  end
end
