module Admin
  class SeopagesController < BaseController
    before_action do
      authorize! :manage, Seopage
    end
    before_action :set_seopage, only: [:show, :edit, :update, :destroy]

    def index
      @seopages = Seopage.page(params[:page])
    end

    def show
    end

    def new
      @seopage = Seopage.new
    end

    def edit
    end

    def create
      @seopage = Seopage.new(seopage_params)

      respond_to do |format|
        if @seopage.save
          format.html { redirect_to admin_seopage_path(@seopage), notice: 'Seopage was successfully created.' }
          format.json { render :show, status: :created, location: @seopage }
        else
          format.html { render :new }
          format.json { render json: @seopage.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        if @seopage.update(seopage_params)
          format.html { redirect_to admin_seopage_path(@seopage), notice: 'Seopage was successfully updated.' }
          format.json { render :show, status: :ok, location: @seopage }
        else
          format.html { render :edit }
          format.json { render json: @seopage.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @seopage.destroy
      redirect_to admin_seopages_url, notice: 'Seopage was successfully destroyed.'
    end

    private

    def set_seopage
      @seopage = Seopage.find(params[:id])
    end

    def seopage_params
      params.require(:seopage).permit(:professtion_id, :service_id, :city_id, :page_title, :page_description, :content, :meta_tags, :h1, :h3_one, :h3_two, :breadcrumb)
    end
  end
end
