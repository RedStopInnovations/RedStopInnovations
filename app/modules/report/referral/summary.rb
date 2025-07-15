module Report
  module Referral
    class Summary
      class Options
        attr_accessor :search, :start_date, :end_date, :status,
                      :referral_type, :include_archived, :practitioner_ids,
                      :without_appointments, :reject_reason

        def initialize(attrs = {})
          @start_date = attrs[:start_date]
          @end_date = attrs[:end_date]
          @include_archived = attrs[:include_archived]
          @without_appointments = attrs[:without_appointments]
          @status = attrs[:status]
          @referral_type = attrs[:referral_type]
          @search = attrs[:search]
          @practitioner_ids = attrs[:practitioner_ids]
          @reject_reason = attrs[:reject_reason]
        end

        def to_param
          params = {}

          if search.present?
            params[:search] = search.presence
          end

          if status.present?
            params[:status] = status
          end

          if start_date.present?
            params[:start_date] = start_date.strftime('%Y-%m-%d')
          end

          if end_date.present?
            params[:end_date] = end_date.strftime('%Y-%m-%d')
          end

          if referral_type.present?
            params[:referral_type] = referral_type
          end

          if reject_reason.present?
            params[:reject_reason] = reject_reason
          end

          if include_archived
            params[:include_archived] = 1
          end

          params
        end
      end

      attr_reader :business, :result, :options

      def initialize(business, options)
        @business = business
        @options = options
        make_result
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << [
            "ID",
            "Client ID",
            "Client",
            "Location",
            'Address line 1',
            'Address line 2',
            'City',
            'State',
            'Postcode',
            "Aboriginal status",
            "Next of kin",

            "Referrer name",
            "Referrer business name",
            "Referrer phone",
            "Referrer email",

            "Professions",
            "Availability type",
            "Practitioner",

            "Referral receive date",
            "Contact referrer date",
            "Contact client date",
            "First appointment date",
            "Send treatment plan date",
            "Send service agreement date",

            "Additional information",
            "Referral reason",
            "Medical note",
            "Priority",
            "Status",

            "Approved at",
            "Rejected at",
            "Reject reason",
            "Referral type",
            "Created at",

            "Medicare details",
            "DVA details",
            "NDIS details",
            "Home care package details",
            "Hospital in home details",
            "Health insurance details",
            "STRC details",
          ]

          @result[:referrals].to_a.each do |ref|
            formatted_insurance_details = format_patient_insurrance_details_for_csv_export(ref)
            csv << [
              ref.id,
              ref.patient_id,
              ref.patient_name,
              ref.patient_address,
              ref.patient_attrs[:address1],
              ref.patient_attrs[:address2],
              ref.patient_attrs[:city],
              ref.patient_attrs[:state],
              ref.patient_attrs[:postcode],
              ref.patient_attrs[:aboriginal_status],
              ref.patient_attrs[:next_of_kin],
              ref.referrer_name,
              ref.referrer_business_name,
              ref.referrer_phone,
              ref.referrer_email,
              ref.professions.join(', '),
              ref.availability_type&.name,
              ref.practitioner.try(:full_name),
              ref.receive_referral_date,
              ref.contact_referrer_date,
              ref.contact_patient_date,
              ref.first_appoinment_date,
              ref.send_treatment_plan_date,
              ref.send_service_agreement_date,
              ref.summary_referral,
              ref.referral_reason,
              ref.medical_note,
              ref.priority,
              ref.status,
              ref.approved_at,
              ref.rejected_at,
              ref.reject_reason,
              ref.type.present? ? I18n.t("referral_types.#{ref.type}") : 'General',
              ref.created_at,
              formatted_insurance_details[:medicare],
              formatted_insurance_details[:dva],
              formatted_insurance_details[:ndis],
              formatted_insurance_details[:hcp],
              formatted_insurance_details[:hih],
              formatted_insurance_details[:hi],
              formatted_insurance_details[:strc],
            ]
          end
        end
      end

      def empty?
        @result[:referrals].empty?
      end

      private

      def make_result
        @result = {}

        @result[:referrals] = referrals_query
      end

      def referrals_query
        query = business.referrals.includes(:practitioner).
          where("referrals.status IS NOT NULL").
          order(Arel.sql("CASE referrals.status WHEN '#{::Referral::STATUS_PENDING}' THEN 1
                WHEN '#{::Referral::STATUS_APPROVED}' THEN 2
                ELSE 3 END ASC, created_at DESC"))

        if options.practitioner_ids.present?
          query = query.where(practitioner_id: options.practitioner_ids)
        end

        if options.search.present?
          # TODO: OPTIMIZE. This is a slow query. Need a refactor.
          query = query.where('LOWER(patient_attrs) LIKE :search OR LOWER(referrer_name) LIKE :search OR LOWER(referrer_business_name) LIKE :search', search: "%#{options.search.downcase}%")
        end

        if options.status.present?
          query = query.where('referrals.status' => options.status)
        end

        if options.start_date.present?
          query = query.where('referrals.created_at >= ?', options.start_date.beginning_of_day)
        end

        if options.end_date.present?
          query = query.where('referrals.created_at <= ?', options.end_date.end_of_day)
        end

        if !options.include_archived
          query = query.where('referrals.archived_at IS NULL')
        end

        if options.without_appointments
          query = query.left_joins(patient: :appointments).having('COUNT(appointments.id) = 0')
        end

        if options.referral_type.present?
          if options.referral_type == ::Referral::TYPE_GENERAL
            query = query.where('type IS NULL OR type = ?', ::Referral::TYPE_GENERAL)
          else
            query = query.where(type: options.referral_type)
          end
        end

        if options.reject_reason.present?
          query = query.where('LOWER(reject_reason) LIKE ?', "%#{options.reject_reason.downcase}%")
        end

        query = query.group('referrals.id')

        query
      end

      def format_patient_insurrance_details_for_csv_export(referral)
        patient = Patient.new(referral.patient_attrs)
        insurance_details = {}

        insurance_details[:medicare] =
          unless patient.medicare_details.values.all?(&:blank?)
            patient.medicare_details.map do |k, v|
              "#{k.delete_prefix('medicare_').humanize}: #{v}"
            end.join("\n")
          end

        insurance_details[:dva] =
          unless patient.dva_details.values.all?(&:blank?)
            patient.dva_details.map do |k, v|
              "#{k.delete_prefix('dva_').humanize}: #{v}"
            end.join("\n")
          end

        insurance_details[:ndis] =
          unless patient.ndis_details.values.all?(&:blank?)
            patient.ndis_details.map do |k, v|
              "#{k.delete_prefix('ndis_').humanize}: #{v}"
            end.join("\n")
          end

        insurance_details[:hcp] =
          unless patient.hcp_details.values.all?(&:blank?)
            patient.hcp_details.map do |k, v|
              "#{k.delete_prefix('hcp_').humanize}: #{v}"
            end.join("\n")
          end

        insurance_details[:hih] =
          unless patient.hih_details.values.all?(&:blank?)
            patient.hih_details.map do |k, v|
              "#{k.delete_prefix('hih_').humanize}: #{v}"
            end.join("\n")
          end

        insurance_details[:hi] =
          unless patient.hi_details.values.all?(&:blank?)
            patient.hi_details.map do |k, v|
              "#{k.delete_prefix('hi_').humanize}: #{v}"
            end.join("\n")
          end

        insurance_details[:strc] =
          unless patient.strc_details.values.all?(&:blank?)
            patient.strc_details.map do |k, v|
              "#{k.delete_prefix('strc_').humanize}: #{v}"
            end.join("\n")
          end

        insurance_details
      end
    end
  end
end
