module Report
  module Eclaim
    class Ndis
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
        CSV.generate(headers: true) do |csv|
          csv << [
            "RegistrationNumber",
            "NDISNumber",
            "SupportsDeliveredFrom",
            "SupportsDeliveredTo",
            "SupportNumber",
            "ClaimReference",
            "Quantity",
            "Hours",
            "UnitPrice",
            "GSTCode"
          ]

          @result[:invoices].to_a.each_with_index do |inv, idx|
            appt = inv.appointment
            pract = inv.practitioner
            patient = inv.patient
            has_tax  = inv.tax_amount > 0
            duration = nil
            invoice_item = inv.items.find do |ii|
              options.billable_item_ids.include?(ii.invoiceable_id.to_s)
            end

            if appt && appt.appointment_type
              duration = self.class.format_appointment_type_duration(appt.appointment_type.duration)
            end

            csv << [
              pract.medicare,
              patient.ndis_client_number,
              inv.service_date.strftime('%F'),
              inv.service_date.strftime('%F'),
              invoice_item&.item_number,
              inv.invoice_number,
              invoice_item&.quantity,
              duration,
              invoice_item&.unit_price,
              has_tax ? 'P1' : 'P2'
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
          .includes(:patient, :items, :practitioner, :appointment)
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

      def self.format_appointment_type_duration(mins)
        hours = mins / 60
        minutes = (mins) % 60
        hours_formatted = hours.to_s.rjust(2, '0')
        minutes_formatted = minutes.to_s.rjust(2, '0')
        "#{ hours_formatted }:#{ minutes_formatted }"
      end
    end
  end
end
