class AppointmentsController < ApplicationController
  include HasABusiness

  before_action :find_appointment, only: [
    :destroy, :modal_review_request, :send_review_request,
    :mark_confirmed, :mark_unconfirmed,
    :mark_invoice_required, :mark_invoice_not_required,
    :modal_send_follow_up_reminder
  ]

  def index
    authorize! :manage, Appointment

    @appointments = current_business.
      appointments.
      includes(:practitioner, :patient).
      order(start_time: :desc).
      page(params[:page])
  end

  def show
    authorize! :read, Appointment

    @appointment = current_business.appointments.with_deleted.find(params[:id])
    @invoices = Invoice.where(appointment_id: @appointment.id)
    @treatment_notes = Treatment.where(appointment_id: @appointment.id)
  end

  def destroy
    authorize! :destroy, Appointment

    DeleteAppointmentService.new.call(current_business, @appointment, current_user)
    redirect_back fallback_location: calendar_url,
                  notice: 'The appointment has been successfully deleted'
  end

  def modal_review_request
    @practitioner = @appointment.practitioner
    @review = Review.where(practitioner_id: @appointment.practitioner_id, patient_id: @appointment.patient_id).first

    @review_request_communication = current_business.communications.where(
      category: 'satisfaction_review_request',
      source: @appointment
    ).order(created_at: :desc).first
  end

  def send_review_request
    begin
      SendReviewRequestService.new.call(@appointment)
      render(
        json: { message: "The request has been sent to the client." },
      )
    rescue SendReviewRequestService::Exception => e
      render(
        json: { message: e.message },
        status: :bad_request
      )
    end
  end

  def mark_confirmed
    @appointment.is_confirmed = true
    @appointment.save!(
      validate: false
    )

    redirect_back fallback_location: appointment_url(@appointment),
                  notice: 'The appointment has been marked as confirmed'
  end

  def mark_unconfirmed
    @appointment.is_confirmed = false
    @appointment.save!(
      validate: false
    )

    redirect_back fallback_location: appointment_url(@appointment),
                  notice: 'The appointment has been marked as unconfirmed'
  end

  def mark_invoice_required
    @appointment.is_invoice_required = true
    @appointment.save!(
      validate: false
    )

    redirect_back fallback_location: appointment_url(@appointment),
                  notice: 'The appointment has been updated'
  end

  def mark_invoice_not_required
    @appointment.is_invoice_required = false
    @appointment.save!(
      validate: false
    )

    redirect_back fallback_location: appointment_url(@appointment),
                  notice: 'The appointment has been updated'
  end

  def bulk_mark_invoice_not_required
    authorize! :manage, Appointment

    current_business.appointments.where(id: params[:appointment_ids].to_a).update_all(is_invoice_required: false)

    redirect_back fallback_location: tasks_url,
                  notice: 'The appointments has been updated'
  end

  def bulk_send_review_request
    authorize! :manage, Appointment

    begin
      BulkSendReviewRequestService.new.call(current_business, params[:appointment_ids].to_a)
      flash[:notice] = 'The review request has been scheduled to send'
    rescue BulkSendReviewRequestService::Exception => e
      flash[:notice] = "An error has occurred: #{e.message}"
    end

    redirect_back fallback_location: dashboard_url
  end

  def modal_send_follow_up_reminder
    authorize! :manage, Appointment
  end

  def appointments_count_daily
    query_date =  Date.strptime(params[:date], '%Y-%m-%d')

    start_date = query_date.beginning_of_month
    end_date = query_date.end_of_month
    results = {}

    if current_user.is_practitioner?
      query =
      "
        SELECT COUNT(id) AS appointments_count, to_char(start_time AT TIME ZONE 'UTC' AT TIME ZONE :timezone, 'YYYY-MM-DD') AS date
        FROM appointments
        WHERE practitioner_id = :practitioner_id
          AND start_time BETWEEN :start_time AND :end_time
          AND cancelled_at IS NULL
          AND deleted_at IS NULL
        GROUP BY to_char(start_time AT TIME ZONE 'UTC' AT TIME ZONE :timezone, 'YYYY-MM-DD')
      "
      query_results = ActiveRecord::Base.connection.exec_query(
        ActiveRecord::Base.send(:sanitize_sql_array, [query, {
          start_time: start_date.beginning_of_day,
          end_time: end_date.end_of_day,
          practitioner_id: current_user.practitioner.id,
          timezone: Time.zone.name
        }])
      ).to_a

      query_results.each do |row|
        results[row['date']] = row['appointments_count']
      end
    end

    render json: {
      data: results
    }
  end

  def list_by_date
    selected_date = Date.strptime(params[:date], '%Y-%m-%d')

    if current_user.is_practitioner?
      appointments = Appointment.where(practitioner_id: current_user.practitioner.id)
        .where(start_time: selected_date.beginning_of_day..selected_date.end_of_day)
        .order(Arel.sql('start_time ASC, "order" ASC'))
        .where(cancelled_at: nil)

      render template: 'dashboard/_calendar_appointments_list',
        layout: false, locals: {
        appointments: appointments, selected_date: selected_date
      }
    end
  end

  private

  def find_appointment
    @appointment = current_business.appointments.find(params[:id])
  end
end
