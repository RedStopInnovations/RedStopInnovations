class TasksController < ApplicationController
  include HasABusiness

  before_action :find_task, only: [
    :edit, :update, :destroy, :show,
    :complete,
    :modal_update_completion,
    :mark_invoice_required,
    :mark_invoice_not_required
  ]

  def index
    authorize! :manage, Task
    tasks_query = current_business.tasks

    respond_to do |f|
      f.html do
        @search_query = tasks_query.ransack ransack_params

        @tasks = @search_query.result(distinct: true).
          includes(:owner, task_users: :user).
          order(id: :desc).
          page(params[:page])
      end

      f.csv do
        raw_ransack_params = params[:q]

        export_options = OpenStruct.new(
          users_id: raw_ransack_params[:task_users_user_id_eq],
          search: raw_ransack_params[:name_cont],
          status: raw_ransack_params[:task_users_status_eq],
        )

        export = Export::Tasks.new(current_business, export_options)
        send_data export.as_csv, filename: "tasks_export_#{Time.current.strftime('%Y%m%d')}.csv"
      end
    end
  end

  def mine
    ahoy_track_once 'View my tasks page'
    tasks_query = Task.where(task_users: { user_id: current_user.id })

    @search_query = tasks_query.ransack ransack_params

    @tasks = @search_query.result(distinct: true).
      includes(:owner, :task_users).
      order(id: :desc).
      page(params[:page])
  end

  def new
    authorize! :create, Task

    @task = Task.new(
      priority: Task::PRIORITY_MEDIUM
    )

    if params[:follow_up_appointment_id]
      appt = current_business.appointments.find_by(id: params[:follow_up_appointment_id])

      if appt
        build_follow_up_appointment_task @task, appt
        @task.patient_id = appt.patient_id
      end
    end
  end

  def create
    authorize! :create, Task

    @task = current_business.tasks.new task_params
    @task.owner_id = current_user.id

    if @task.save
      Webhook::Worker.perform_later(@task.id, WebhookSubscription::TASK_CREATED)

      @task.users.each do |user|
        UserMailer.notification_new_task(@task, user).deliver_later
      end

      respond_to do |f|
        f.html do
          redirect_to tasks_url, notice: 'Task was successfully created.'
        end

        f.json do
          render json: { task: @task }
        end
      end
    else
      respond_to do |f|
        f.html {
          flash.now[:alert] = 'Failed to create task. Please check for form errors.'
          render :new
        }

        f.json do
          render(json: {
            errors: @task.errors.full_messages
          }, status: 422)
        end
      end
    end
  end

  def show
  end

  def edit
    authorize! :edit, @task
  end

  def update
    authorize! :update, @task

    @task.assign_attributes task_params

    # @TODO: notification if new assignee?
    if @task.save
      respond_to do |f|
        f.html do
          redirect_to tasks_url, notice: 'Task was successfully updated.'
        end

        f.json do
          render json: {task: @task }
        end
      end
    else
      respond_to do |f|
        f.html do
          flash.now[:alert] = 'Failed to update the task. Please check for form errors.'
          render :edit
        end

        f.json do
          render(json: {
            message: 'Failed to update the task. Please check for form errors.',
            errors: @task.errors.full_messages
          }, status: 422)
        end
      end
    end
  end

  def complete
    # authorize! :update, @task
    task_user = @task.task_users.find_by user_id: current_user.id

    task_completion_params = params.require(:completion).permit(
      :date, :duration
    )

    # @TODO: validation
    task_user_update_params = {
      status: TaskUser::STATUS_COMPLETE,
      complete_at: Date.parse(task_completion_params[:date]).beginning_of_day,
      completion_duration: task_completion_params[:duration]
    }

    if task_user && task_user.update(task_user_update_params)
      redirect_back fallback_location: tasks_url,
                  notice: 'The task has been mark as completed.'
    else
      redirect_back fallback_location: tasks_url,
                  alert: 'The task is not assigned to you.'
    end
  end

  def modal_update_completion
    @task_user = @task.task_users.find_by! user_id: current_user.id
  end

  def destroy
    authorize! :destroy, @task

    @task.destroy

    redirect_back fallback_location: tasks_url,
                  notice: 'The task was successfully deleted.'
  end

  def mark_invoice_required
    authorize! :update, @task

    @task.is_invoice_required = true
    @task.save!(
      validate: false
    )

    redirect_back fallback_location: task_url(@task),
                  notice: 'The task has been updated'
  end

  def mark_invoice_not_required
    authorize! :update, @task

    @task.is_invoice_required = false
    @task.save!(
      validate: false
    )

    redirect_back fallback_location: task_url(@task),
                  notice: 'The task has been updated'
  end

  def bulk_mark_invoice_not_required
    authorize! :update, Task

    current_business.tasks.where(id: params[:task_ids].to_a).update_all(is_invoice_required: false)

    redirect_back fallback_location: tasks_url,
                  notice: 'The tasks has been updated'
  end

  def new_completed
    @task = Task.new(
      priority: Task::PRIORITY_MEDIUM
    )
  end

  def create_completed
    form = CreateCompleteTaskForm.new(
      params.require(:task).permit(
        :name,
        :patient_id,
        :description,
        :complete_at,
        :completion_duration
      ).merge(business: current_business)
    )

    if form.valid?
      create_params = params.require(:task).permit(
        :name,
        :patient_id,
        :description,
        :is_invoice_required
      ).to_h.merge(
        due_on: Date.current,
        owner_id: current_user.id,
        priority: Task::PRIORITY_MEDIUM,
        task_users_attributes: [{
          user_id: current_user.id,
          status: TaskUser::STATUS_COMPLETE,
          complete_at: Date.parse(form.complete_at).beginning_of_day,
          completion_duration: form.completion_duration.presence
        }]
      )

      @task = current_business.tasks.new(create_params)
      @task.save!(validate: false)

      respond_to do |f|
        f.html do
          redirect_to tasks_url, notice: 'The completed task was successfully created.'
        end

        f.json do
          render json: { task: @task }
        end
      end
    else
      respond_to do |f|
        f.html {
          flash.now[:alert] = 'Failed to add task. Please check for form errors.'
          render :new
        }

        f.json do
          render(json: {
            errors: form.errors.full_messages
          }, status: 422)
        end
      end
    end
  end

  private

  def ransack_params
    result = params[:q].try(:to_unsafe_h) || {}

    if result[:task_users_status_eq].nil?
      result[:task_users_status_eq] = TaskUser::STATUS_OPEN
    end

    result
  end

  def find_task
    @task = current_business.tasks.find(params[:id])
  end

  def task_params
    params.require(:task).permit(
      :priority,
      :name,
      :patient_id,
      :due_on,
      :description,
      :is_invoice_required,
      user_ids: []
    )
  end

  def build_follow_up_appointment_task(task, appointment)
    patient = appointment.patient
    practitioner = appointment.practitioner

    task.name = "Contact #{patient.full_name} for checkup"
    task.user_ids = [practitioner.user_id]
    task.due_on = appointment.start_time.to_date + 14.days
    if task.due_on.past?
      task.due_on = Time.current.to_date + 7.days
    end

    task.priority = Task::PRIORITY_MEDIUM
    task.description =
      "#{patient.full_name} had their last appointment on #{appointment.start_time_in_practitioner_timezone.strftime(I18n.t('date.common'))}. Can you please contact them to check on their progress? If they require further appointments please contact admin to make the booking.\n"
  end
end
