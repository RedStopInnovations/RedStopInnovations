module Admin
  class ReportsController < BaseController
    def index
      case current_admin_user.role
      when AdminUser::SUPER_ADMIN_ROLE
        render 'index'
      else
        redirect_to admin_dashboard_url
      end
    end
  end
end
