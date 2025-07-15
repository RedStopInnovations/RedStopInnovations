module Admin
  class ReportsController < BaseController

    def index
      case current_admin_user.role
      when AdminUser::SUPER_ADMIN_ROLE
        render 'index'
      when AdminUser::MARKETPLACE_ADMIN_ROLE
        render 'marketplace_report'
      else
        redirect_to admin_dashboard_url
      end
    end
  end
end
