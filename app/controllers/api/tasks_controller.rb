module Api
  class TasksController < BaseController
    # @TODO: authorize actions

    def completed
      @tasks = Calendar.new(current_business).completed_client_tasks(
        params[:from_date].to_date,
        params[:to_date].to_date,
        params[:practitioner_ids]
      )

      render :index
    end

    def show
      @task = current_business.tasks.find(params[:id])
    end
  end
end
