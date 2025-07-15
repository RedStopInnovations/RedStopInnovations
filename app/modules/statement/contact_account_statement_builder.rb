module Statement
  class ContactAccountStatementBuilder
    attr_reader :contact, :filter

    def initialize(contact, filter)
      @contact = contact
      @filter = filter
    end

    def result
      @result ||= begin
        {
          invoices: invoices_query.load,
          payments: payments_query.load
        }
      end
    end

    private

    def invoices_query
      q =
        contact.
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

      if filter.patient_id.present?
        q = q.where(patient_id: filter.patient_id)
      end

      case filter.invoice_status
      when 'Paid'
        q = q.where("invoices.outstanding = 0")
      when 'Outstanding'
        q = q.where("invoices.outstanding > 0")
      end

      q = q.preload(:patient, items: [:invoiceable], appointment: [:practitioner])

      q
    end

    def payments_query
      q =
        contact.payments.
        includes(payment_allocations: :invoice).
        where("payments.amount > 0").
        where(deleted_at: nil).
        where("invoices.deleted_at IS NULL").
        order(payment_date: :desc).
        group("payments.id")

      if filter.patient_id.present?
        q = q.where(patient_id: filter.patient_id)
      end

      case filter.invoice_status
      when 'Paid'
        q = q.where("invoices.outstanding = 0")
      when 'Outstanding'
        q = q.where("invoices.outstanding > 0")
      end

      case filter.type
      when 'Activity'
        q = q.where(payment_date: filter.start_date..filter.end_date)
      when 'Account', 'Super'
        q = q.where(invoices: { id: invoices_query.pluck(:id) })
      end

      q
    end
  end
end
