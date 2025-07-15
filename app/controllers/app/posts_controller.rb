module App
  class PostsController < ApplicationController
    include HasABusiness

    before_action :set_post, only: [:show, :edit, :update, :destroy]

    def index
      authorize! :read, Post

      @posts = current_business.posts.
                includes(:practitioner).
                order('created_at DESC').
                page(params[:page])
    end

    def show
      authorize! :read, Post
    end

    def new
      authorize! :create, Post
      @post = Post.new
    end

    def edit
      authorize! :edit, @post
    end

    def create
      authorize! :create, Post

      @post = current_user.practitioner.posts.new(post_params)

      if @post.save
        redirect_to app_posts_path,
                    notice: 'Post was successfully created.'
      else
        flash.now[:alert] = 'Failed to create post. Please check for form errors.'
        render :new
      end
    end

    def update
      authorize! :update, @post

      if @post.update(post_params)
        redirect_to app_posts_path,
                    notice: 'Post was successfully updated.'
      else
        flash.now[:alert] = 'Failed to update post. Please check for form errors.'
        render :edit
      end
    end

    def destroy
      authorize! :destroy, @post

      @post.destroy

      redirect_to app_posts_url,
                  notice: 'Post was successfully deleted.'
    end

    private

    def set_post
      @post = current_business.posts.find(params[:id])
    end

    def post_params
      params.require(:post).permit(
        :title,
        :thumbnail,
        :meta_description,
        :meta_keywords,
        :summary,
        :content
      )
    end


  end
end
