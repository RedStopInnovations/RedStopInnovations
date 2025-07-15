module Report
  module Eclaim
    class Medicare
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
            "TypeOfService",
            "ServiceTypeCde",
            "ExternalPatientId",
            "ExternalInvoice",
            "ExtServicingDoctor",
            "Practitioner First Name",
            "Practitioner Last Name",
            "ReferringProviderNum",
            "ReferralIssueDate",
            "ReferralPeriod",
            "PatientFirstName",
            "PatientFamilyName",
            "PatientDateOfBirth",
            "PatientMedicareCardNum",
            "PatientReferenceNum",
            "DateOfService",
            "ItemNum1",
            "NoOfPatientsSeen",
            "RefDrFirstName",
            "RefDrLastName",
            "ReferralPeriodTypeCde",
            "AccountPaidInd",
            "TotalPatientContribAmt",
            "ClaimSubmissionAuthorised"
          ]

          @result[:invoices].to_a.each_with_index do |inv, idx|
            pract = inv.practitioner
            patient = inv.patient
            invoice_item = inv.items.find do |ii|
              options.billable_item_ids.include?(ii.invoiceable_id.to_s)
            end

            account_paid_ind = inv.paid? ? 'Y' : 'N'
            total_patient_contrib_amt =
              if inv.paid?
                inv.amount
              else
                inv.amount - inv.outstanding
              end

            csv << [
              'M',
              'S',
              patient.id,
              inv.invoice_number,
              pract.medicare,
              pract.first_name,
              pract.last_name,
              patient.medicare_referrer_provider_number,
              patient.medicare_referral_date.try(:to_date).try(:strftime, '%Y-%m-%d'),
              24,
              patient.first_name,
              patient.last_name,
              patient.dob&.strftime('%Y-%m-%d'),
              patient.medicare_card_number,
              patient.medicare_card_irn,
              inv.service_date.strftime('%Y-%m-%d'),
              invoice_item&.item_number,
              '1',
              '',
              '',
              'S',
              account_paid_ind,
              total_patient_contrib_amt,
              'Y'
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
