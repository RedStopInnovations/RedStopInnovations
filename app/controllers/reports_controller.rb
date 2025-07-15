class ReportsController < ApplicationController
  include HasABusiness

  before_action do
    authorize! :read, :reports
  end

  def index
  end

  def deleted_items
    @report = Report::DeletedItems.make current_business, params

    respond_to do |f|
      f.html
      f.csv { send_data @report.as_csv }
    end
  end
end
