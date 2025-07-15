# == Schema Information
#
# Table name: task_users
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  task_id             :integer
#  status              :string
#  complete_at         :datetime
#  updated_at          :datetime
#  completion_duration :integer
#
# Indexes
#
#  index_task_users_on_task_id  (task_id)
#  index_task_users_on_user_id  (user_id)
#

class TaskUser < ApplicationRecord
  include RansackAuthorization::TaskUser

  STATUS = [
    STATUS_OPEN = 'Open',
    STATUS_COMPLETE = 'Complete'
  ]

  belongs_to :task
  belongs_to :user

  before_validation :set_status

  validates :status, inclusion: { in: STATUS }

  def status_complete?
    status == STATUS_COMPLETE
  end

  private

  def set_status
    self.status = STATUS_OPEN if self.status.blank?
  end
end
