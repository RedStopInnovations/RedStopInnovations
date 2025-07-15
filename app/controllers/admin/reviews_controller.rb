module Admin
  class ReviewsController < BaseController
    before_action do
      authorize! :manage, Review
    end
    before_action :set_review, only: [:show, :edit, :update, :destroy]

    def index
      @reviews = Review.includes(:practitioner).
        order(id: :desc).
        page(params[:page])
    end

    def new
      @review = Review.new
    end

    def create
      @review = Review.new(review_params)

      if @review.save
        redirect_to admin_reviews_url,
                    notice: 'The review has been successfully created.'
      else
        flash.now[:alert] = 'Please check for form errors.'
        render :new
      end
    end

    def show
      redirect_to edit_admin_review_url(@review)
    end

    def update
      if @review.update(review_params)
        redirect_to edit_admin_review_path(@review),
                    notice: 'The review has been updated.'
      else
        flash.now[:alert] = 'Please check for form errors.'
        render :edit
      end
    end

    def destroy
      @review.destroy

      redirect_to admin_reviews_url,
                  notice: 'The review has been successfully deleted.'
    end

    private

    def set_review
      @review = Review.find params[:id]
    end

    def review_params
      params.require(:review).permit(
        :patient_name,
        :practitioner_id,
        :rating,
        :comment,
        :approved,
        :publish_rating,
        :publish_comment
      )
    end
  end
end
