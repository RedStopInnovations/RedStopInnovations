module Report
  module Transactions
    class PaymentsSummary
      attr_reader :business, :result, :options, :payments_sum

      def self.make(business, options)
        new(business, options)
      end

      def initialize(business, options)
        @business = business
        @options = options
        parse_options
        calculate
      end

      def payments
        payments_query.
          order(payment_date: :desc).
          preload(:patient, :created_version, payment_allocations: {invoice: :patient})
      end

      def payments_sum
        @payments_sum ||= payments_query.select("
          SUM(eftpos) AS eftpos_total,
          SUM(hicaps) AS hicaps_total,
          SUM(cash) AS cash_total,
          SUM(medicare) AS medicare_total,
          SUM(workcover) AS workcover_total,
          SUM(dva) AS dva_total,
          SUM(other) AS other_total,
          SUM(stripe_charge_amount) AS stripe_total,
          SUM(direct_deposit) AS direct_deposit_total,
          SUM(cheque) AS cheque_total
        ").group(:business_id).order(business_id: :asc).first
      end

      def as_csv
        CSV.generate(headers: true) do |csv|
          csv << ["ID", "Date", "Client ID", "Client", "Invoice", "Source(s)", "Total", "Author"]

          payments.each do |payment|
            sources_lines = []
            sources_lines << "Hicaps: $#{payment.hicaps}" if payment.hicaps.to_f > 0
            sources_lines << "Eftpos: $#{payment.eftpos}" if payment.eftpos.to_f > 0
            sources_lines << "Cash: $#{payment.cash}" if payment.cash.to_f > 0
            sources_lines << "Medicare: $#{payment.medicare}" if payment.medicare.to_f > 0
            sources_lines << "Workcover: $#{payment.workcover}" if payment.workcover.to_f > 0
            sources_lines << "Dva: $#{payment.dva}" if payment.dva.to_f > 0
            sources_lines << "Stripe: $#{payment.stripe_charge_amount}" if payment.stripe_charge_amount.to_f > 0
            sources_lines << "Direct Deposit: $#{payment.direct_deposit}" if payment.direct_deposit.to_f > 0
            sources_lines << "Cheque: $#{payment.cheque}" if payment.cheque.to_f > 0
            sources_lines << "Other: $#{payment.other}" if payment.other.to_f > 0

            # TODO: format_money
            csv << [
              payment.id,
              payment.payment_date.strftime('%d %b %Y'),
              payment.patient.id,
              payment.patient.full_name,
              "#{payment.invoices.map(&:invoice_number).join(',')}",
              sources_lines.join("\n").to_s.strip,
              "$#{payment.amount}",
              payment.created_version&.author&.full_name
            ]
          end
        end
      end

      private
      def parse_options
        # TODO: shit here
        options[:start_date] = options[:start_date].try(:to_date) || 7.days.ago.to_date
        options[:end_date] = options[:end_date].try(:to_date) || Date.current
      end

      def calculate
      end

      def payments_query
        query = Payment.unscoped
                .joins(:patient)
                .where("patients.deleted_at IS NULL")
                .where("payments.payment_date >= ?", options[:start_date])
                .where("payments.payment_date <= ?", options[:end_date])
                .where("payments.deleted_at IS NULL")
                .where(business_id: business.id)

        if options[:payment_types].present?
          query = query.where("eftpos > 0") if options[:payment_types].include?("Eftpos")
          query = query.where("hicaps > 0") if options[:payment_types].include?("Hicaps")
          query = query.where("cash > 0") if options[:payment_types].include?("Cash")
          query = query.where("medicare > 0") if options[:payment_types].include?("Medicare")
          query = query.where("workcover > 0") if options[:payment_types].include?("Workcover")
          query = query.where("dva > 0") if options[:payment_types].include?("Dva")
          query = query.where("stripe_charge_amount > 0") if options[:payment_types].include?("Stripe")
          query = query.where("direct_deposit > 0") if options[:payment_types].include?("Direct Deposit")
          query = query.where("cheque > 0") if options[:payment_types].include?("Cheque")
          query = query.where("other > 0") if options[:payment_types].include?("Other")
        end

        query = query.where(patient_id: options[:patient_ids]) if options[:patient_ids].present?

        query
      end
    end
  end
end
