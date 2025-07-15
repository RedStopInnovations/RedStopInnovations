module Dashboard
  # Overview report for practitioner users
  class PractitionerOverviewReport
    STATS_RANGES = [
      'current_month',
      'last_30_days',
      'last_60_days',
      'last_90_days',
      'month_to_date',
      'year_to_date',
    ]

    CACHE_EXPIRE = 12.hours

    attr_reader :business, :practitioner, :current_date

    attr_reader :appointment_stats
    attr_reader :transaction_stats
    attr_reader :appointments_last_12_months_chart_data
    attr_reader :invoices_total_last_12_months_chart_data

    def initialize(business, practitioner)
      @business = business
      @practitioner = practitioner

      @current_date = Time.current.to_date
      @stats_cache_key_prefix = [
        'practitioner_overview_report',
        practitioner.id.to_s,
        current_date.beginning_of_day.to_i
      ].join('.')

      calculate
    end

    def calculate
      @appointment_stats = Rails.cache.fetch(@stats_cache_key_prefix + '.appointment_stats', expires_in: CACHE_EXPIRE) do
        calculate_appointment_stats
      end

      @transaction_stats = Rails.cache.fetch(@stats_cache_key_prefix + '.transaction_stats', expires_in: CACHE_EXPIRE) do
        calculate_transaction_stats
      end

      @appointments_last_12_months_chart_data = Rails.cache.fetch(@stats_cache_key_prefix + '.appointments_last_12_months_chart_data', expires_in: CACHE_EXPIRE) do
        calculate_appointments_last_12_months_chart_data
      end

      @invoices_total_last_12_months_chart_data = Rails.cache.fetch(@stats_cache_key_prefix + '.invoices_total_last_12_months_chart_data', expires_in: CACHE_EXPIRE) do
        calculate_invoices_total_last_12_months_chart_data
      end
    end

    def calculate_appointment_stats
      appointment_stats = {}

      STATS_RANGES.each do |range|
        time_range = parse_time_range(range)

        appointments_query = Appointment.
          where(practitioner_id: practitioner.id).
          joins(:appointment_type).
          where(start_time: time_range).
          where(cancelled_at: nil, deleted_at: nil).
          where(appointment_type: {availability_type_id: [
            AvailabilityType::TYPE_HOME_VISIT_ID,
            AvailabilityType::TYPE_FACILITY_ID
          ]})

        # Total appointments exclude cancelled
        appointments_count = appointments_query.count
        # Total appointments booked online
        booked_online_count = appointments_query.where(booked_online: true).count
        # Total unique patients
        patients_count = appointments_query.count('DISTINCT patient_id')

        referrals_count = business.referrals.
          where(created_at: time_range).
          where(practitioner_id: practitioner.id).
          count

        availability_query = Availability.
          appointment_availability.
          where(practitioner_id: practitioner.id).
          where(start_time: time_range)

        appointments_count = appointments_query.count
        patients_count = appointments_query.count('DISTINCT patient_id')
        visit_average = appointments_count.zero? ? 0 : (appointments_count.to_f / patients_count.to_f).round(1)

        availability_max_allocations = availability_query.sum('availabilities.max_appointment')
        occupancy = appointments_count.zero? ? 0 : (appointments_count.to_f / availability_max_allocations.to_f * 100).round(1)

        total_driving_distance = (availability_query.sum("(availabilities.cached_stats->'travel_distance')::integer").to_f / 1000).round(2)
        total_driving_duration = (availability_query.sum("(availabilities.cached_stats->'travel_duration')::integer").to_f / 3600).round(2)
        total_availability_time = (availability_query.sum("(availabilities.cached_stats->'availability_duration')::integer").to_f / 3600).round(2)
        total_appointment_time = (availability_query.sum("(availabilities.cached_stats->'appointments_duration')::integer").to_f / 3600).round(2)
        total_vacant_time = (total_availability_time - total_appointment_time - total_driving_duration).round(2)

        if total_vacant_time < 0
          total_vacant_time = 0
        end

        appointment_stats[range] = {
          appointments_count: appointments_count,
          booked_online_count: booked_online_count,
          patients_count: patients_count,
          referrals_count: referrals_count,

          visit_average: visit_average,
          occupancy: occupancy,
          total_driving_distance: total_driving_distance,
          total_driving_duration: total_driving_duration,
          total_availability_time: total_availability_time,
          total_vacant_time: total_vacant_time,
        }
      end

      appointment_stats
    end

    def calculate_transaction_stats
      transaction_stats = {}

      STATS_RANGES.each do |range|
        time_range = parse_time_range(range)

        invoices_query = business.invoices.
          where(practitioner_id: practitioner.id).
          where(created_at: time_range).
          where(deleted_at: nil)

        created_invoices_count = invoices_query.count
        total_amount = invoices_query.sum(:amount).round(2)
        average_invoice_amount = invoices_query.average(:amount).to_f.round(2)

        product_sales_count = InvoiceItem.where(invoiceable_type: Product.name).where(invoice_id: invoices_query).sum(&:quantity)
        product_sales_amount = InvoiceItem.where(invoiceable_type: Product.name).where(invoice_id: invoices_query).sum(&:amount)

        transaction_stats[range] = {
          created_invoices_count: created_invoices_count,
          total_invoices_amount: total_amount,
          average_invoice_amount: average_invoice_amount,
          product_sales_count: product_sales_count,
          product_sales_amount: product_sales_amount
        }
      end

      transaction_stats
    end

    def calculate_appointments_last_12_months_chart_data
      chart_data = {}

      date_range = 12.months.ago.beginning_of_month..1.month.ago.end_of_month

      groups_by_month = business.appointments
          .where(start_time: date_range)
          .where(practitioner_id: practitioner.id)
          .where(cancelled_at: nil)
          .pluck(:start_time)
          .group_by do |start_time|
          start_time.beginning_of_month.to_date
        end

      tmp_date = 12.months.ago.beginning_of_month.to_date

      dataset_labels = []
      dataset_data = []

      12.times do
        dataset_labels << tmp_date.strftime('%b')
        dataset_data << if groups_by_month[tmp_date]
            groups_by_month[tmp_date].count
          else
            0
          end
        tmp_date = tmp_date.next_month
      end

      chart_data[:labels] = dataset_labels
      chart_data[:datasets] = [
        {
          label: 'Appointments',
          data: dataset_data
        }
      ]

      chart_data
    end

    def calculate_invoices_total_last_12_months_chart_data
      chart_data = {}

      date_range = 12.months.ago.beginning_of_month..1.month.ago.end_of_month

      groups_by_month = business.invoices
          .joins(:appointment)
          .where('appointments.practitioner_id' => practitioner.id)
          .where('appointments.created_at' => date_range)
          .select('invoices.created_at, invoices.amount')
          .where('invoices.deleted_at IS NULL')
          .group_by do |inv|
          inv.created_at.beginning_of_month.to_date
        end

      tmp_date = 12.months.ago.beginning_of_month.to_date

      dataset_labels = []
      dataset_data = []

      12.times do
        dataset_labels << tmp_date.strftime('%b')
        dataset_data <<
          if groups_by_month[tmp_date]
            groups_by_month[tmp_date].sum(&:amount)
          else
            0
          end
        tmp_date = tmp_date.next_month
      end

      chart_data[:labels] = dataset_labels
      chart_data[:datasets] = [
        {
          label: 'Invoices amount',
          data: dataset_data
        }
      ]

      chart_data
    end

    private

    def parse_time_range(range)
      base_time = current_date.beginning_of_day

      case range
      when 'current_month'
        base_time.beginning_of_month...base_time.end_of_month
      when 'last_30_days'
        (base_time - 30.days).beginning_of_day...base_time.end_of_day
      when 'last_60_days'
        (base_time - 60.days).beginning_of_day...base_time.end_of_day
      when 'last_90_days'
        (base_time - 90.days).beginning_of_day...base_time.end_of_day
      when 'month_to_date'
        base_time.beginning_of_month...base_time.end_of_day
      when 'year_to_date'
        base_time.beginning_of_year...base_time.end_of_day
      else
        raise ArgumentError.new("Unknown range: #{range}")
      end
    end
  end
end