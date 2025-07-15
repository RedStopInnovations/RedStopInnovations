module Report
  module Admin
    class LifetimeValueSummary
      attr_reader :lifetime_value_for, :page, :payments

      def self.make(lifetime_value_for, page)
        new(lifetime_value_for, page)
      end

      def initialize(lifetime_value_for, page)
        @lifetime_value_for = lifetime_value_for
        @page = page
        calculate
      end

      def empty?
        !payments.present?
      end

      private

      def calculate

        case lifetime_value_for
        when "patient"
          scope = SubscriptionBilling.joins(:business_invoice, appointment: :patient)
                        .where("business_invoices.payment_status = 'paid'")
                        .select(select_query('patients', 'patient_id'))
                        .group('appointments.patient_id, patients.first_name, patients.last_name')
                        .order('total_amount desc')
                        .page(page)
        when "practitioner"
          scope = SubscriptionBilling.joins(:business_invoice, appointment: :practitioner)
                        .where("business_invoices.payment_status = 'paid'")
                        .select(select_query('practitioners', 'practitioner_id'))
                        .group('appointments.practitioner_id, practitioners.first_name, practitioners.last_name')
                        .order('total_amount desc')
                        .page(page)
        else
          scope = []
        end

        @payments = scope
      end

      def select_query(field, field_id)
        qry = []
        qry << "appointments.#{field_id}"
        qry << "#{field}.first_name as f_name"
        qry << "#{field}.last_name as l_name"
        qry << "sum(subscription_price_on_date * quantity) as total_amount"
        return qry.join(',')
      end
    end
  end
end
