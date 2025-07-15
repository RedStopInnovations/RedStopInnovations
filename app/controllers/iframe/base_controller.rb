module Iframe
  class BaseController < ApplicationController
    layout 'iframe'

    after_action :allow_iframe
    private
    def allow_iframe
      response.headers["X-FRAME-OPTIONS"] = "ALLOWALL"
    end
  end
end
