module Api
  module V1
    class TaskSerializer < BaseSerializer
      type 'tasks'

      attributes  :name,
                  :priority,
                  :description,
                  :due_on,
                  :status,
                  :updated_at,
                  :created_at

      has_many :assignees do
        data do
          @object.users
        end
      end

      link :self do
        @url_helpers.api_v1_task_url(@object.id)
      end
    end
  end
end
