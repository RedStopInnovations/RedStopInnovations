class RejectReferralService
  def call(business, referral, options = {})
    if referral.status == Referral::STATUS_PENDING_MULTIPLE
      current_business.referrals.delete @referral
    elsif referral.business_id == business.id
      # TODO: validate reason text
      if options[:reject_reason].present?
        referral.reject_reason = options[:reject_reason]
      end
      referral.status = Referral::STATUS_REJECTED
      referral.rejected_at = Time.current
      referral.save!(validate: false)
    end
  end
end
