json.extract!(
  task,
  :id, :name, :priority, :description, :owner_id, :due_on, :created_at, :updated_at
)

json.owner do
  json.extract! task.owner, :id, :first_name, :last_name, :full_name
end

json.patient do
  if task.patient.present?
    json.partial! 'patients/patient', patient: task.patient
  end
end

json.task_users do
  json.array! task.task_users do |task_user|
    json.extract! task_user, :id, :user_id, :status, :complete_at, :completion_duration, :updated_at
    json.user do
      json.extract! task_user.user, :id, :first_name, :last_name, :full_name
    end
  end
end
