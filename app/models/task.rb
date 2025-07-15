# == Schema Information
#
# Table name: tasks
#
#  id                  :integer          not null, primary key
#  name                :string
#  priority            :string
#  description         :text
#  due_on              :date
#  status              :string
#  business_id         :integer
#  owner_id            :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  patient_id          :integer
#  is_invoice_required :boolean          default(TRUE)
#
# Indexes
#
#  index_tasks_on_business_id  (business_id)
#  index_tasks_on_owner_id     (owner_id)
#

class Task < ApplicationRecord
  include RansackAuthorization::Task

  PRIORITIES = [
    PRIORITY_HIGHT  = 'High',
    PRIORITY_MEDIUM = 'Medium',
    PRIORITY_LOW    = 'Low'
  ]

  belongs_to :business
  belongs_to :patient, required: false

  has_many :task_users,
           inverse_of: :task,
           dependent: :destroy,
           autosave: :true
  has_many :users, class_name: "User", through: :task_users
  has_many :invoices
  belongs_to :owner, class_name: "User", foreign_key: :owner_id

  accepts_nested_attributes_for :task_users, reject_if: :all_blank, allow_destroy: :true

  validates :priority, presence: true, inclusion: { in: PRIORITIES }
  validates_presence_of :name, :users

  validates_length_of :name, maximum: 250
  validates_length_of :description, maximum: 1000

  def has_user_complete?
    task_users.any? { |task_user| task_user.status_complete? }
  end
end
