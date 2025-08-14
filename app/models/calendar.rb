class Calendar
  attr_reader :business

  def initialize(business)
    @business = business
  end

  # NOTE:
  #  - Careful with timezone of from/to dates.
  #  - Availability start/end times stored in database is in UTC time zone.
  def availabilities(from_date, to_date, practitioner_ids = [])
    # OPTIMIZE: optimze query
    availabilities_query =
      Availability.
        where(business_id: business.id).
        not_deleted.
        includes(
          :contact,
          :group_appointment_type,
          :availability_subtype,
          practitioner: [:user, :business_hours],
          appointments: [
            :patient, :appointment_type, :invoice,
            :treatment_note, :arrival, :bookings_answers,
            practitioner: [:user]
          ]
        ).
        where(
          start_time: from_date.to_date.beginning_of_day..to_date.to_date.end_of_day
        )

    query_practitioner_ids =
      if practitioner_ids.present?
        business.practitioners.where(id: practitioner_ids).pluck(:id)
      else
        business.practitioners.active.pluck(:id)
      end

    availabilities_query = availabilities_query.where(practitioner_id: query_practitioner_ids)

    availabilities_query.load
  end

  def completed_client_tasks(from_date, to_date, practitioner_ids = [])
    query_user_ids =
      if practitioner_ids.present?
        business.practitioners.where(id: practitioner_ids).pluck(:user_id)
      else
        business.practitioners.active.pluck(:user_id)
      end

    tasks_query =
      Task.
        where(business_id: business.id).
        includes(
          :owner,
          :patient,
          task_users: :user,
        ).
        where(
          task_users: {
            complete_at: from_date.to_date.beginning_of_day..to_date.to_date.end_of_day,
            user_id: query_user_ids
          }
        )

    tasks_query.load
  end
end
