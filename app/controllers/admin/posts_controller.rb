module Admin
  class PostsController < BaseController
    before_action do
      authorize! :manage, Post
    end

    before_action :set_post, only: [:show, :edit, :update, :approval, :destroy]

    def index
      @search_query = Post.ransack(params[:q].try(:to_unsafe_h))

      @posts = @search_query.result
                                .order(created_at: :desc)
                                .page(params[:page])
    end

    def show
    end

    def edit
    end

    def update
      if @post.update(post_params)
        redirect_to admin_post_url(@post),
                    notice: 'Post was successfully updated.'
      else
        flash.now[:alert] = 'Failed to update post. Please check for form errors.'
        render :edit
      end
    end

    def approval
      @post.update_columns(published: !@post.published?)
      flash[:notice] = 'Post was successfully updated'
      redirect_back fallback_location: admin_post_url(@post)
    end

    def destroy
      @post.destroy
      redirect_to admin_posts_url,
                  notice: 'Post was successfully deleted.'
    end

    private

    def set_post
      @post = Post.find(params[:id])
    end

    def post_params
      params.require(:post).permit(
        :title,
        :thumbnail,
        :meta_description,
        :meta_keywords,
        :summary,
        :published
      )
    end
  end
end
