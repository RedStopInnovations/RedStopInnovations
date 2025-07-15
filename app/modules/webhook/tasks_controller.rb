module Api
  module V1
    class TasksController < V1::BaseController
      before_action :find_task, only: [:show, :update, :destroy]

      def index
        tasks = current_business.
          tasks.
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: tasks,
               meta: pagination_meta(tasks)
      end

      def show
        render jsonapi: @task,
               include: [:assignees]
      end

      def poll
        task = current_business.tasks
                               .order(id: :desc)
                               .first
        result = []
        result << Webhook::Task::Serializer.new(task).as_json if task
        render json: result
      end

      private

      def find_task
        @task = current_business.tasks.find(params[:id])
      end
    end
  end
end
