module PatientBulkArchiveSearch
  class Searcher
    attr_reader :business
    attr_reader :filters
    attr_reader :base_time

    def initialize(business, filters, base_time)
      @business = business
      @filters = filters
      @base_time = base_time
    end

    # @TODO: rewrite count query
    def results_count
      query.page.total_count
    end

    def paginated_results
      query.page(filters.page).per(filters.per_page)
    end

    def results
      query.load
    end

    private

    def query
      query = business.patients.not_archived

      query = query.select('patients.id, patients.first_name, patients.last_name, patients.full_name, patients.dob, patients.address1, patients.address2, patients.city, patients.state, patients.postcode, patients.country, patients.created_at, patients.archived_at')

      if filters.contact_id.present?
        query = query.joins(:patient_contacts).
          where(patient_contacts: {contact_id: filters.contact_id})
      end

      if filters.create_date_from.present?
        query = query.where('patients.created_at >= ?', filters.create_date_from.to_date.beginning_of_day)
      end

      if filters.create_date_to.present?
        query = query.where('patients.created_at <= ?', filters.create_date_to.to_date.end_of_day)
      end

      if filters.no_appointment_period.present?
        threshold_date = nil

        case filters.no_appointment_period
        when '6m'
          threshold_date = base_time - 6.months
        when '9m'
          threshold_date = base_time - 9.months
        when '1y'
          threshold_date = base_time - 1.years
        when '2y'
          threshold_date = base_time - 2.years
        when '3y'
          threshold_date = base_time - 3.years
        else # all the time
        end

        if threshold_date
          query = query.joins("LEFT JOIN appointments ON appointments.patient_id = patients.id AND appointments.start_time >= '#{threshold_date.in_time_zone('UTC').strftime('%Y-%m-%d %H:%M:%S')}'").
            where('appointments.id IS NULL')
        else
          query = query.joins('LEFT JOIN appointments ON appointments.patient_id = patients.id').
            where('appointments.id IS NULL')
        end
      end

      if filters.no_invoice_period.present?
        threshold_date = nil

        case filters.no_invoice_period
        when '6m'
          threshold_date = base_time - 6.months
        when '9m'
          threshold_date = base_time - 9.months
        when '1y'
          threshold_date = base_time - 1.years
        when '2y'
          threshold_date = base_time - 2.years
        when '3y'
          threshold_date = base_time - 3.years
        else # all the time
        end

        if threshold_date
          query = query.joins("LEFT JOIN invoices ON invoices.patient_id = patients.id AND invoices.created_at >= '#{threshold_date.in_time_zone('UTC').strftime('%Y-%m-%d %H:%M:%S')}'").
            where('invoices.id IS NULL')
        else
          query = query.joins('LEFT JOIN invoices ON invoices.patient_id = patients.id').
            where('invoices.id IS NULL')
        end
      end

      if filters.no_treatment_note_period.present?
        threshold_date = nil

        case filters.no_treatment_note_period
        when '6m'
          threshold_date = base_time - 6.months
        when '9m'
          threshold_date = base_time - 9.months
        when '1y'
          threshold_date = base_time - 1.years
        when '2y'
          threshold_date = base_time - 2.years
        when '3y'
          threshold_date = base_time - 3.years
        else # all the time
        end

        if threshold_date
          query = query.joins("LEFT JOIN treatments ON treatments.patient_id = patients.id AND treatments.created_at >= '#{threshold_date.in_time_zone('UTC').strftime('%Y-%m-%d %H:%M:%S')}'").
            where('treatments.id IS NULL')
        else
          query = query.joins('LEFT JOIN treatments ON treatments.patient_id = patients.id').
            where('treatments.id IS NULL')
        end
      end

      query = query.group('patients.id')

      query.order(id: :asc)
    end
  end
end