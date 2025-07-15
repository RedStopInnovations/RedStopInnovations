# @TODO: remove later
module Report
  module Practitioners
    class PerformanceLegacy

      class Options
        attr_accessor :practitioner_ids,
                      :practitioner_group_ids,
                      :start_date,
                      :end_date

        def initialize(raw_options = {})
          @start_date = raw_options[:start_date]
          @end_date = raw_options[:end_date]
          @practitioner_ids = raw_options[:practitioner_ids]
          @practitioner_group_ids = raw_options[:practitioner_group_ids]
        end

        def to_params
          params = {}

          if start_date.present?
            params[:start_date] = start_date.strftime('%Y-%m-%d')
          end

          if end_date.present?
            params[:end_date] = end_date.strftime('%Y-%m-%d')
          end

          if practitioner_ids.present?
            params[:practitioner_ids] = practitioner_ids
          end

          if practitioner_group_ids.present?
            params[:practitioner_group_ids] = practitioner_group_ids
          end

          params
        end
      end

      attr_reader :business, :options, :result

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        calculate
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << [
            "Practitioner ID",
            "Practitioner",
            "Practitioner profession",
            "Practitioner state",
            "Practitioner group",

            "Total appointments",
            "Occupancy",
            "Cancelation",
            "Invoice total",
            "Invoice total ex tax",
            "Average invoice",
            "PVA",
            "Treatment notes created",
            "Letters created",

            "Availability duration (hrs)",
            "Appointment duration (hrs)",
            "Travel duration (hrs)",
            "Vacant time (hrs)",
          ]

          @result[:data].each do |row|
            pract = row[:practitioner]
            pract_group_col = pract.groups.to_a.map(&:name).join(';')
            csv << [
              pract.id,
              pract.full_name,
              pract.profession,
              pract.state,
              pract_group_col,

              row['appointments_count'],
              ((row['appointments_count'].to_f / row['max_appointments'].to_f) * 100).round(2).to_s + "%",
              row['cancelleds_count'],
              row['invoiced_amount'].to_f.round(2).to_s,
              row['invoiced_amount_ex_tax'].to_f.round(2).to_s,
              (row['invoiced_amount'].to_f / (row['invoices_count'].zero? ? 1 : row['invoices_count'])).round(2).to_s,
              row['appointments_count'].to_i.zero? ? 0 : (row['appointments_count'].to_f / row['patients_count'].to_f).round(1),
              row['treatment_notes_count'],
              row['letters_count'],

              (row['availability_duration'].to_f / 3600).round(2),
              (row['appointments_duration'].to_f / 3600).round(2),
              (row['travel_duration'].to_f / 3600).round(2),
              (row['vacant_duration'].to_f / 3600).round(2)
            ]
          end
        end
      end

      private

      def calculate
        @result = {}
        query = "
          SELECT

            COALESCE((
              SELECT
                SUM(invoices.amount)
              FROM invoices
              WHERE
                invoices.practitioner_id = PRAC.id
                AND invoices.deleted_at IS NULL
                AND invoices.issue_date >= :start_time
                AND invoices.issue_date <= :end_time
              GROUP BY PRAC.id
            ), 0) AS invoiced_amount,

            COALESCE((
              SELECT
                COUNT(invoices.id)
              FROM invoices
              WHERE
                invoices.practitioner_id = PRAC.id
                AND invoices.deleted_at IS NULL
                AND invoices.issue_date >= :start_time
                AND invoices.issue_date <= :end_time
              GROUP BY PRAC.id
            ), 0) AS invoices_count,

            COALESCE((
              SELECT
                SUM(invoices.amount_ex_tax)
              FROM invoices
              WHERE
                invoices.practitioner_id = PRAC.id
                AND invoices.deleted_at IS NULL
                AND invoices.issue_date >= :start_time
                AND invoices.issue_date <= :end_time
              GROUP BY PRAC.id
            ), 0) AS invoiced_amount_ex_tax,

            COALESCE((
              SELECT
                COUNT(DISTINCT appointments.patient_id)
              FROM appointments
              JOIN appointment_types AT ON AT.id = appointments.appointment_type_id
              WHERE
                appointments.practitioner_id = PRAC.id
                AND appointments.deleted_at IS NULL
                AND appointments.cancelled_at IS NULL
                AND appointments.start_time >= :start_time
                AND appointments.start_time <= :end_time
                AND AT.availability_type_id IN (:availability_type_ids)
              GROUP BY PRAC.id
            ), 0) AS patients_count,

            COALESCE((
              SELECT
                COUNT(appointments.id)
              FROM appointments
              JOIN appointment_types AT ON AT.id = appointments.appointment_type_id
              WHERE
                appointments.practitioner_id = PRAC.id
                AND appointments.cancelled_at IS NOT NULL
                AND appointments.start_time >= :start_time
                AND appointments.start_time <= :end_time
                AND AT.availability_type_id IN (:availability_type_ids)
              GROUP BY PRAC.id
            ), 0) AS cancelleds_count,

            COALESCE(SUM(AVAI.max_appointment), 0) AS max_appointments,
            COALESCE(SUM((AVAI.cached_stats->'appointments_count')::integer), 0) AS appointments_count,

            COALESCE(SUM((AVAI.cached_stats->'availability_duration')::integer), 0) AS availability_duration,
            COALESCE(SUM((AVAI.cached_stats->'appointments_duration')::integer), 0) AS appointments_duration,
            COALESCE(SUM((AVAI.cached_stats->'travel_duration')::integer), 0) AS travel_duration,
            COALESCE(SUM((AVAI.cached_stats->'remaining_availability_duration')::integer), 0) AS vacant_duration,

            PRAC.id AS practitioner_id,
            PRAC.full_name,
            PRAC.profession,
            PRAC.state
          FROM
            availabilities AVAI
          INNER JOIN practitioners PRAC
            ON AVAI.practitioner_id = PRAC.id
          WHERE
            AVAI.business_id = :business_id
            AND AVAI.start_time >= :start_time
            AND AVAI.start_time <= :end_time
            AND AVAI.availability_type_id IN (:availability_type_ids)
        "

        query += " AND AVAI.practitioner_id IN (:practitioner_ids)" if report_practitioner_ids.present?
        query += " GROUP BY PRAC.id"
        query += " ORDER BY PRAC.full_name ASC"

        created_treatment_notes_by_practitioners = get_created_treatment_notes_by_practitioners
        created_letters_by_practitioners = get_created_letters_by_practitioners

        @result[:data] ||= ActiveRecord::Base.connection.exec_query(
          ActiveRecord::Base.send(:sanitize_sql_array, [query, {
            start_time: options.start_date.beginning_of_day,
            end_time: options.end_date.end_of_day,
            business_id: business.id,
            practitioner_ids: report_practitioner_ids,
            availability_type_ids: [
              AvailabilityType::TYPE_HOME_VISIT_ID,
              AvailabilityType::TYPE_FACILITY_ID
            ]
          }])
        )

        unless report_practitioner_ids.present?
        # Only show practitioners who has at least one appt
          @result[:data] = @result[:data].filter do |row|
            row['appointments_count'] > 0
          end
        end

        pract_ids = report_practitioner_ids

        unless pract_ids.present?
          pract_ids = business.practitioners.pluck(:id)
        end

        practitioners = Practitioner.where(id: pract_ids).includes(:groups)

        @result[:data].each do |row|
          practitioner_id = row['practitioner_id'].to_i
          # Bind practitioner object to use for better displaying
          row[:practitioner] = practitioners.find { |pract| pract.id == practitioner_id }

          row['treatment_notes_count'] = created_treatment_notes_by_practitioners[practitioner_id].to_i
          row['letters_count'] = created_letters_by_practitioners[practitioner_id].to_i
        end

        @result[:total_patients_count] =
          Appointment.where(
            practitioner_id: pract_ids
          ).
          where(
            'start_time >= ? AND end_time <= ?',
            options.start_date.beginning_of_day,
            options.end_date.end_of_day
          ).
          where(
            'deleted_at IS NULL AND cancelled_at IS NULL'
          ).
          count('DISTINCT patient_id')
      end

      def get_created_treatment_notes_by_practitioners
        query = "
          SELECT
            practitioners.id AS practitioner_id, COUNT(treatments.id) AS treatment_notes_count
          FROM practitioners
            LEFT JOIN treatments ON treatments.author_id = practitioners.user_id
          WHERE
            treatments.created_at >= :start_time
            AND treatments.created_at <= :end_time
        "
        query += " AND practitioners.id IN (:practitioner_ids)" if report_practitioner_ids.present?
        query += " GROUP BY practitioners.id"

        results = ActiveRecord::Base.connection.exec_query(
          ActiveRecord::Base.send(:sanitize_sql_array, [query, {
            start_time: options.start_date.beginning_of_day,
            end_time: options.end_date.end_of_day,
            business_id: business.id,
            practitioner_ids: report_practitioner_ids
          }])
        )

        results.to_a.each_with_object({}) do |row, hash|
          hash[row['practitioner_id']] = row['treatment_notes_count'].present? ? row['treatment_notes_count'] : 0
        end
      end

      def get_created_letters_by_practitioners
        query = "
          SELECT
            practitioners.id AS practitioner_id, COUNT(patient_letters.id) AS letters_count
          FROM practitioners
            LEFT JOIN patient_letters ON patient_letters.author_id = practitioners.user_id
          WHERE
            patient_letters.created_at >= :start_time
            AND patient_letters.created_at <= :end_time
        "
        query += " AND practitioners.id IN (:practitioner_ids)" if report_practitioner_ids.present?
        query += " GROUP BY practitioners.id"

        results = ActiveRecord::Base.connection.exec_query(
          ActiveRecord::Base.send(:sanitize_sql_array, [query, {
            start_time: options.start_date.beginning_of_day,
            end_time: options.end_date.end_of_day,
            business_id: business.id,
            practitioner_ids: report_practitioner_ids
          }])
        )

        results.to_a.each_with_object({}) do |row, hash|
          hash[row['practitioner_id']] = row['letters_count'].present? ? row['letters_count'] : 0
        end
      end

      def report_practitioner_ids
        @report_practitioner_ids ||= begin
          query = Practitioner.where(business_id: business.id)

          if options.practitioner_ids.present?
            query = query.where(id: options.practitioner_ids)
          elsif options.practitioner_group_ids.present?
            practitioner_ids = []

            business.groups.where(id: options.practitioner_group_ids).each do |group|
              practitioner_ids += group.practitioners.pluck(:id)
            end

            query = query.where(id: practitioner_ids)
          else
            # Only report active practitioner by default
            query = query.active
          end

          query.pluck :id
        end
      end
    end
  end
end
