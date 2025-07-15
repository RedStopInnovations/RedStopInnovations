module Report
  module Appointments
    class UninvoicedTasks
      class Options
        attr_accessor :user_ids,
                      :patient_ids,
                      :start_date,
                      :end_date,
                      :page

        def to_params
          {
            start_date: start_date.strftime("%Y-%m-%d"),
            end_date: end_date.strftime("%Y-%m-%d"),
            user_ids: user_ids,
            patient_ids: patient_ids
          }
        end
      end

      attr_reader :business, :options, :results

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        calculate
      end

      private

      def calculate
        @results = {}

        @results[:paginated_tasks] = tasks_query
          .preload(task: [:patient])
          .page(options.page)
          .per(25)
      end

      def tasks_query
        query = TaskUser.
                joins(:task).
                joins("
                  LEFT JOIN invoices ON invoices.task_id = tasks.id
                  AND invoices.deleted_at IS NULL
                ").
                where("invoices.id IS NULL").
                where(status: TaskUser::STATUS_COMPLETE).
                where('tasks.patient_id IS NOT NULL AND complete_at IS NOT NULL').
                where("complete_at >= ?", options.start_date.beginning_of_day).
                where("complete_at <= ?", options.end_date.end_of_day).
                where("tasks.business_id" => business.id).
                where("tasks.is_invoice_required" => true).
                order('complete_at DESC')

        query = query.where(user_id: options.user_ids) if options.user_ids.present?
        query = query.where('tasks.patient_id' => options.patient_ids) if options.patient_ids.present?

        query
      end
    end
  end
end
