module Api
  module V1
    class ReferralAttachmentsController < V1::BaseController
      before_action :find_referral

      def index
        attachments = @referral.
          attachments.
          order(id: :asc).
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: attachments,
               meta: pagination_meta(attachments)
      end

      def show
        attachment = @referral.attachments.find(params[:id])

        render jsonapi: attachment
      end

      private

      def find_referral
        @referral = current_business.referrals.find(params[:referral_id])
      end

    end
  end
end
