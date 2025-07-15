class BusinessAdminDashboard
  attr_reader :business
  attr_reader :current_user

  attr_reader :uninvoiced_appointments
  attr_reader :patients_without_upcoming_appointments
  attr_reader :recent_open_tasks
  attr_reader :recent_assigned_open_tasks
  attr_reader :recent_pending_referrals
  attr_reader :recent_pending_assigned_referrals

  def initialize(business, current_user)
    @business = business
    @current_user = current_user
    calculate
  end

  private

  def fetch_patients_without_upcoming_appointments(limit = 5)
    if current_user.is_practitioner? && !(current_user.role_administrator? || current_user.role_supervisor? || current_user.role_restricted_supervisor?)
      current_practitioner_id = current_user.practitioner.id
        query = "
          SELECT
            patients.id, patients.full_name, patients.city, patients.state,
            (
              SELECT
                appointments.id
              FROM appointments
              WHERE
                appointments.patient_id = patients.id
                AND appointments.deleted_at IS NULL
                AND appointments.cancelled_at IS NULL
                AND appointments.start_time >= :start_time
                AND appointments.start_time < :now
              ORDER BY appointments.start_time DESC
              LIMIT 1
            ) AS last_appointment_id

          FROM patients

          INNER JOIN appointments PAST_APPT
            ON PAST_APPT.patient_id = patients.id
            AND PAST_APPT.deleted_at IS NULL
            AND PAST_APPT.cancelled_at IS NULL
            AND PAST_APPT.start_time >= :start_time
            AND PAST_APPT.end_time <= :now

          LEFT JOIN appointments FUTURE_APPT
            ON FUTURE_APPT.patient_id = patients.id
            AND FUTURE_APPT.deleted_at IS NULL
            AND FUTURE_APPT.cancelled_at IS NULL
            AND FUTURE_APPT.start_time > :now

          WHERE
            patients.deleted_at IS NULL AND
            patients.archived_at IS NULL AND
            patients.business_id = :business_id AND
            PAST_APPT.practitioner_id = :last_practitioner_id

          GROUP BY patients.id
          HAVING COUNT(FUTURE_APPT.id) = 0
          ORDER BY patients.full_name ASC
          LIMIT :limit
        "
        start_date = 60.days.ago
        now = Time.current
        rows = Patient.connection.exec_query(Patient.sanitize_sql_array(
            [
              query,
              {
                start_time: start_date,
                now: now,
                business_id: business.id,
                last_practitioner_id: current_practitioner_id,
                limit: limit
              }
            ]
        ))

        last_appointment_ids = rows.pluck 'last_appointment_id'
        last_appointments = Appointment.where(id: last_appointment_ids).includes(:patient, :appointment_type, practitioner: :user)

        rows.each do |row|
          row['last_appointment'] = last_appointments.find { |appt| appt.id == row['last_appointment_id'] }
        end

        rows
    else
      []
    end
  end

  def fetch_uninvoiced_appointments(limit = 3)
    if current_user.role_administrator? || current_user.role_supervisor? || current_user.role_restricted_supervisor?
      business.appointments
        .joins("LEFT JOIN invoices ON invoices.appointment_id = appointments.id")
        .includes(:patient, :practitioner, :appointment_type)
        .where('end_time < ?', Time.current)
        .where("invoices.id IS NULL")
        .where("appointments.cancelled_at IS NULL")
        .where('appointments.is_invoice_required' => true)
        .order(start_time: :desc)
        .limit(limit)
        .to_a
    elsif current_user.is_practitioner?
      business.appointments
        .joins("LEFT JOIN invoices ON invoices.appointment_id = appointments.id")
        .includes(:patient, :practitioner, :appointment_type)
        .where('end_time < ?', Time.current)
        .where("invoices.id IS NULL")
        .where("appointments.cancelled_at IS NULL")
        .where('appointments.is_invoice_required' => true)
        .where("practitioners.id" => current_user.practitioner.id)
        .order(start_time: :desc)
        .limit(limit)
        .to_a
    else
      []
    end
  end

  def fetch_recent_open_tasks(limit = 3)
    business.tasks.includes(task_users: :user)
            .where(task_users: { status: TaskUser::STATUS_OPEN })
            .order(:priority, due_on: :desc)
            .limit(limit)
            .to_a
  end

  def fetch_recent_assigned_open_tasks(limit = 3)
    business.tasks.includes(task_users: :user)
            .where(task_users: {user_id: @current_user.id})
            .where(task_users: { status: TaskUser::STATUS_OPEN })
            .order(:priority, due_on: :desc)
            .limit(limit)
            .to_a
  end

  def fetch_recent_pending_referrals(limit = 3)
    business.referrals
    .where(status: [Referral::STATUS_PENDING, Referral::STATUS_APPROVED])
    .where(archived_at: nil)
    .order(
      Arel.sql("CASE status WHEN '#{::Referral::STATUS_PENDING}' THEN 1 WHEN '#{::Referral::STATUS_APPROVED}' THEN 2 ELSE 3 END ASC, created_at DESC")
    )
    .limit(limit)
    .to_a
  end

  def fetch_recent_pending_assigned_referrals(limit = 3)
    if current_user.is_practitioner?
      business.referrals
      .where(status: [Referral::STATUS_PENDING, Referral::STATUS_APPROVED])
      .where(archived_at: nil)
      .order(
        Arel.sql("CASE status WHEN '#{::Referral::STATUS_PENDING}' THEN 1 WHEN '#{::Referral::STATUS_APPROVED}' THEN 2 ELSE 3 END ASC, created_at DESC")
      )
      .where(practitioner_id: @current_user.practitioner.id)
      .limit(limit)
      .to_a
    else
      []
    end
  end

  def calculate
    @uninvoiced_appointments = fetch_uninvoiced_appointments
    @recent_pending_referrals = fetch_recent_pending_referrals
    @recent_pending_assigned_referrals = fetch_recent_pending_assigned_referrals
    @recent_open_tasks = fetch_recent_open_tasks
    @recent_assigned_open_tasks = fetch_recent_assigned_open_tasks
    @patients_without_upcoming_appointments = fetch_patients_without_upcoming_appointments
  end
end
