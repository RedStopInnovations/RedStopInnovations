module TasksHelper
  def user_option_for_task(business)
    options = []
    options << ['-- Assignees --', nil]
    business.users.active.order(full_name: :asc).each do |user|
      options << [user.full_name, user.id]
    end
    options
  end

  def get_priority_class(priority)
    result = "bg-red" if priority == Task::PRIORITY_HIGHT

    result = "bg-yellow" if priority == Task::PRIORITY_MEDIUM
    result = "bg-gray" if priority == Task::PRIORITY_LOW

    result
  end

end
