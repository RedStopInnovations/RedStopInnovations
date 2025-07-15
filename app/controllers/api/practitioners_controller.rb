module Api
  class PractitionersController < BaseController
    def search
      keyword = params[:s].to_s.presence

      @practitioners =
        if keyword
          current_business.practitioners.
            active.
            ransack(full_name_cont: keyword).
            result.
            limit(params[:limit] || 25).
            order(full_name: :asc)
        else
          []
        end
    end
  end
end
