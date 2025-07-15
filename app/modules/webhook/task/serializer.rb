module Webhook
  module Task
    class Serializer

      attr_reader :task

      def initialize(task)
        @task = task
      end

      def as_json(options = {})
        attrs = task.attributes.symbolize_keys.slice(
          :id,
          :name,
          :priority,
          :description,
          :due_on,
          :updated_at,
          :created_at
        )
        attrs[:assignees] = []
        task.users.each do |user|
          attrs[:assignees] << ::Webhook::User::Serializer.new(user).as_json
        end
        attrs
      end
    end
  end
end