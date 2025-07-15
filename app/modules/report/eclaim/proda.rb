module Report
  module Eclaim
    class Proda
      attr_reader :business, :options, :result

      def initialize(business, options)
        @business = business
        @options = options
        calculate
      end

      def empty?
        result[:invoices].blank?
      end

      def as_csv
        CSV.generate(headers: true, force_quotes: true) do |csv|
          csv << [
            "PatientMedicareCardNum",
            "PatientReferenceNum",
            "PatientFirstName",
            "ExtServicingDoctor",
            "DateOfService",
            "ReferringProviderNum",
            "ReferralIssueDate"
          ]

          @result[:invoices].to_a.each_with_index do |inv, idx|
            pract = inv.practitioner
            patient = inv.patient

            csv << [
              patient.medicare_card_number,
              patient.medicare_card_irn,
              patient.first_name,
              pract.medicare,
              inv.service_date.strftime('%Y-%m-%d'),
              patient.medicare_referrer_provider_number,
              patient.medicare_referral_date.try(:to_date).try(:strftime, '%Y-%m-%d')
            ]
          end
        end
      end

      private

      def calculate
        @result = {}
        result[:invoices] = invoices_query.to_a
      end

      def invoices_query
        query = business.invoices
          .where('invoices.practitioner_id IS NOT NULL AND invoices.service_date IS NOT NULL')
          .includes(:patient, :items, :practitioner)
          .where(
            issue_date: options.start_date.beginning_of_day..options.end_date.end_of_day
          )
          .where(
            invoice_items: {
              invoiceable_type: BillableItem.name,
              invoiceable_id: options.billable_item_ids
            }
          )

        if options.unpaid_only
          query = query.where('invoices.outstanding > 0')
        end

        if options.patient_ids.present?
          query = query.where('invoices.patient_id' => options.patient_ids)
        end

        query.order(issue_date: :asc)
      end
    end
  end
end
