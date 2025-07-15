module Admin
  class CalendarController < BaseController
    def index
      redirect_back fallback_location: admin_dashboard_url,
                    alert: 'The calendar is temporary disabled'
    end
  end
end
