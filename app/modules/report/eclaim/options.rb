module Report
  module Eclaim
    class Options
      attr_accessor :start_date,
                    :end_date,
                    :billable_item_ids,
                    :patient_ids,
                    :unpaid_only

      def initialize(attrs = {})
        @start_date = attrs[:start_date]
        @end_date = attrs[:end_date]
        @billable_item_ids = attrs[:billable_item_ids]
        @unpaid_only = attrs[:unpaid_only]
      end

      def valid?
        start_date.present? && end_date.present? && billable_item_ids.is_a?(Array) &&
          !billable_item_ids.empty?
      end

      def to_param
        params = {
          billable_item_ids: billable_item_ids
        }

        if start_date.present?
          params[:start_date] = start_date.strftime('%Y-%m-%d')
        end

        if end_date.present?
          params[:end_date] = end_date.strftime('%Y-%m-%d')
        end

        if unpaid_only.present?
          params[:unpaid_only] = unpaid_only ? 1 : nil
        end

        params
      end
    end
  end
end
