module Report
  module Eclaim
    class Dva
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
            "Number",
            "ExternalPatientId",
            "ExternalInvoice",
            "PatientFirstName",
            "PatientFamilyName",
            "PatientDateOfBirth",
            "PatientGender",
            "TypeOfService",
            "ServiceTypeCde",
            "VaaServiceTypeCde",
            "Service Type",
            "RefDrTitle",
            "RefDrFirstName",
            "RefDrLastName",
            "ReferringProviderNum",
            "Hospital",
            "ReferralIssueDate",
            "ReferralPeriodTypeCde",
            "AcceptedDisabilityInd",
            "AcceptedDisabilityText",
            "VeteranFileNum",
            "TreatmentLocationCde",
            "DateOfService",
            "ExtServicingDoctor",
            "ReferralOverrideTypeCde",

            "AccountPaidInd",
            "TotalPatientContribAmt",
            "ClaimSubmissionAuthorised",

            "ItemNum1",
            "NoOfPatientsSeen1",
            "ServiceText1",

            "ItemNum2",
            "NoOfPatientsSeen2",
            "ServiceText2",

            "ItemNum3",
            "NoOfPatientsSeen3",
            "ServiceText3",

            "ItemNum4",
            "NoOfPatientsSeen4",
            "ServiceText4",

            "ItemNum5",
            "NoOfPatientsSeen5",
            "ServiceText5",
          ]

          @result[:invoices].to_a.each_with_index do |inv, idx|
            appt = inv.appointment
            pract = inv.practitioner
            patient = inv.patient

            invoice_items = inv.items
            treatment_location_code =
            if appt.home_visit?
              'V'
            elsif appt.facility?
              'N'
            else
              nil
            end

            patient_gender = {
              'Male' => 'M',
              'Female' => 'F'
            }[patient.gender]
            items_columns = []

            invoice_items.each do |ii|
              items_columns += [
                ii.item_number,
                '1',
                ''
              ]
            end

            account_paid_ind = inv.paid? ? 'Y' : 'N'
            total_patient_contrib_amt =
              if inv.paid?
                inv.amount
              else
                inv.amount - inv.outstanding
              end

            csv << ([
              idx + 1,
              patient.id,
              inv.invoice_number,
              patient.first_name,
              patient.last_name,
              patient.dob&.strftime('%Y-%m-%d'),
              patient_gender,
              'V',
              'S',
              'J',
              pract.profession,
              'Dr',
              '',
              patient.dva_referrer_name,
              patient.dva_referrer_provider_number,
              patient.dva_hospital,
              patient.dva_referral_date.try(:to_date).try(:strftime, '%Y-%m-%d'),
              'S',
              (patient.dva_card_type == 'White Card' ? 'Y' : 'N'),
              (patient.dva_card_type == 'White Card' ? patient.dva_white_card_disability : ''),
              patient.dva_file_number,
              treatment_location_code,
              inv.service_date.strftime('%Y-%m-%d'),
              pract.medicare,
              '',
              account_paid_ind,
              total_patient_contrib_amt,
              'Y'
            ] + items_columns)
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
