module Export
  class Tasks
    attr_reader :business, :options

    def self.make(business, options)
      new(business, options)
    end

    def initialize(business, options)
      @business = business
      @options = options
    end

    def as_csv
      CSV.generate(headers: true) do |csv|
        csv << [
          'Name',
          'Description',
          'Priority',
          'Due date',
          'Assignees',
          'Created by',
          'Created at',
        ]

        tasks_query.load.each do |task|
          csv << [
            task.name,
            task.description,
            task.priority,
            task.due_on&.strftime(I18n.t('date.common')),
            task.task_users.to_a.map(&:user).map(&:full_name).join(', '),
            task.owner&.full_name,
            task.created_at.strftime(I18n.t('datetime.common')),
          ]
        end
      end
    end

    private

    def tasks_query
      query = business.tasks.
        includes(:owner, task_users: :user).
        joins(:task_users)

      if options.users_id.present?
        query = query.where(task_users: { user_id: options.users_id })
      end

      if options.search.present?
        query = query.where('LOWER(name) LIKE ?', "%#{options.search.to_s.strip.downcase}%")
      end

      if options.status.present?
        query = query.where(task_users: { status: options.status})
      end

      query.group('tasks.id')
    end
  end
end