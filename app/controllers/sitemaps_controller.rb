class SitemapsController < ApplicationController
  def show
    @practitioners = Practitioner.approved.active.public_profile.to_a
    @posts = Post.published.to_a

    respond_to do |format|
      format.xml
    end
  end
end
