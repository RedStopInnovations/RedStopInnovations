module Reports
  class PayrollsController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :read, :reports
    end

    def summary
      ahoy_track_once 'View payrolls report'

      @report = Report::Payrolls::Summary.make current_business, params

      respond_to do |f|
        f.html
        f.csv { send_data @report.as_csv }
      end
    end
  end
end
