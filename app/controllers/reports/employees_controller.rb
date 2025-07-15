module Reports
  class EmployeesController < ApplicationController
    include HasABusiness
    before_action :prepare_data, only: [:roster]

    before_action do
      authorize! :read, :reports
    end

    def roster
      ahoy_track_once 'View employee roster report'

      respond_to do |format|
        format.html
        format.pdf do
          render(
            pdf: "Employee roster",
            template: 'pdfs/employee_roster',
            locals: {
              business: current_business,
              report: @report
            }
          )
        end
      end
    end

    def roster_deliver
      ahoy_track_once 'Send employee roster report'

      practitioner = current_business.practitioners.find(params[:practitioner_id])

      EmployeeMailer::roster_availability(
        practitioner.id,
        params[:start_date],
        params[:end_date]
      ).deliver_later

      flash[:notice] = 'The roster has been sent to employee'

      redirect_to reports_employees_roster_path(
        start_date: params[:start_date],
        end_date: params[:end_date]
      )
    end

    def send_all_rosters
      ahoy_track_once 'Send all employees roster report'

      report = Report::Practitioners::EmployeeRoster.make current_business, params.to_unsafe_h

      report.result[:practitioners].each do |pract|
        EmployeeMailer::roster_availability(
          pract.id,
          params[:start_date],
          params[:end_date]
        ).deliver_later
      end

      flash[:notice] = 'The rosters has been sent to employees'

      redirect_to reports_employees_roster_path(
        start_date: params[:start_date],
        end_date: params[:end_date]
      )
    end

    private

    def prepare_data
      @report = Report::Practitioners::EmployeeRoster.make current_business, params.to_unsafe_h
    end
  end
end
