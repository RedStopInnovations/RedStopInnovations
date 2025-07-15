module Admin
  module Reports
    class AppointmentsController < BaseController
      def appointments_summary
        @report = Report::Admin::Appointments::Summary.new
      end
    end
  end
end
