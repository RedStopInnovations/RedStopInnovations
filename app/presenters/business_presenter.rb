class BusinessPresenter < BasePresenter
  def logo_url
    if Rails.env.production?
      avatar.url
    else
      ApplicationController.helpers.asset_url(avatar.url)
    end
  end
end
