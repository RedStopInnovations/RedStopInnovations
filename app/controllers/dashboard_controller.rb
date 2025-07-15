class DashboardController < ApplicationController
  include HasABusiness

  def index
    if current_user.role_virtual_receptionist?
      redirect_to virtual_receptionist_dashboard_path
    else
      @dashboard = BusinessAdminDashboard.new(current_business, current_user)
    end
  end

  def overview_report_content
    if current_user.role_administrator? || current_user.role_supervisor?
      @business_overview_report = Dashboard::BusinessOverviewReport.new(current_business)
    end

    if current_user.is_practitioner?
      @practitioner_overview_report = Dashboard::PractitionerOverviewReport.new(current_business, current_user.practitioner)
    end

    render template: 'dashboard/_overview_report', layout: false
  end
end