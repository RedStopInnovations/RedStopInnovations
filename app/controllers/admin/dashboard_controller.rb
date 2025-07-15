module Admin
  class DashboardController < BaseController

    def index
      case current_admin_user.role
      when AdminUser::SUPER_ADMIN_ROLE
        @report = AdminOverviewReport.new
        render 'index'
      when AdminUser::MARKETPLACE_ADMIN_ROLE
        render 'marketplace_dashboard'
      when AdminUser::RECEPTIONIST_ROLE
        render 'receptionist_dashboard'
      else
      end
    end

    def settings
      case current_admin_user.role
      when AdminUser::SUPER_ADMIN_ROLE
        render 'settings'
      when AdminUser::MARKETPLACE_ADMIN_ROLE
        render 'marketplace_settings'
      else
        redirect_to admin_dashboard_url
      end
    end
  end
end
