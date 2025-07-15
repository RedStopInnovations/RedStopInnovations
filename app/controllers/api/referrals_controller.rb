module Api
  class ReferralsController < BaseController
    def show
      @referral = current_business.referrals.find(params[:id])
    end
  end
end
