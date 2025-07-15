module Report
  module Admin
    # Report payments for a subscription in different criteria
    class RevenueSummary
      attr_reader :revenue_type, :time_period, :payments

      # @param business ::Business
      # @param start_date Date
      # @param end_date Date
      def self.make(revenue_type, time_period)
        new(revenue_type, time_period)
      end

      def initialize(revenue_type, time_period)
        @revenue_type = revenue_type
        @time_period = time_period
        calculate
      end

      def empty?
        payments.empty?
      end

      private

      def calculate
        # TODO: bad smell
        scope = SubscriptionPayment

        if revenue_type == "public" || revenue_type == "private"
          subscription_plan_id = SubscriptionPlan.find_by_name(revenue_type)
          subscriptions = Subscription.where(subscription_plan_id: subscription_plan_id)
          business_ids = subscriptions.map(&:business_id)
          scope = scope.where(business_id: business_ids)
        end

        if time_period == 'current_month'
          scope = scope.where(payment_date: (Date.today.beginning_of_month - 1.day)..(Date.today + 1.day))
        end

        @payments = scope.order(id: :desc)
      end
    end
  end
end
