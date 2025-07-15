module Statement
  class PatientAccountStatementBuilder
    attr_reader :patient, :filter

    def initialize(patient, filter)
      @patient = patient
      @filter = filter
    end

    def result
      @result ||= begin
        {
          appointments: appointments_query.load,
          invoices: invoices_query.load,
          payments: payments_query.load
        }
      end
    end

    private

    def invoices_query
      q =
        patient.
        invoices.
        joins("LEFT JOIN appointments ON invoices.appointment_id = appointments.id").
        where(
          "(appointments.start_time >= ? AND appointments.start_time <= ?)
          OR (appointments.id IS NULL AND invoices.issue_date >= ? AND invoices.issue_date <= ?)",
          filter.start_date.beginning_of_day,
          filter.end_date.end_of_day,
          filter.start_date,
          filter.end_date
        ).
        where("appointments.cancelled_at IS NULL").
        where("appointments.deleted_at IS NULL").
        where("invoices.deleted_at IS NULL").
        order(issue_date: :desc)

      case filter.invoice_status
      when 'Paid'
        q = q.where("invoices.outstanding = 0")
      when 'Outstanding'
        q = q.where("invoices.outstanding > 0")
      end

      q = q.preload(items: [:invoiceable], appointment: [:practitioner])

      q
    end

    def payments_query
      q =
        patient.
        payments.
        preload(payment_allocations: :invoice).
        joins(payment_allocations: :invoice).
        where("payments.amount > 0").
        where(payments: { deleted_at: nil }).
        where("invoices.deleted_at IS NULL").
        order(payment_date: :desc).
        group("payments.id")

      case filter.invoice_status
      when 'Paid'
        q = q.where("invoices.outstanding = 0")
      when 'Outstanding'
        q = q.where("invoices.outstanding > 0")
      end

      case filter.type
      when 'Activity'
        q = q.where(payment_date: filter.start_date..filter.end_date)
      when 'Account'
        q = q.where(invoices: { id: invoices_query.pluck(:id) })
      end

      q
    end

    def appointments_query
      patient.
        appointments.
        includes(:practitioner).
        where("start_time >= ?", filter.start_date.beginning_of_day).
        where("end_time <= ?", filter.end_date.end_of_day).
        where(cancelled_at: nil).
        where(deleted_at: nil).
        order(start_time: :desc)
    end
  end
end
