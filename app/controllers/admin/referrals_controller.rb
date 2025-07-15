module Admin
  class ReferralsController < BaseController
    before_action do
      authorize! :manage, Referral
    end

    before_action :set_referral, only: [
      :show, :destroy, :assign_business, :send_nearby_practitioners
    ]

    def index
      @referrals_search_query = Referral.ransack(params[:q].try(:to_unsafe_h))
      @referrals = @referrals_search_query.
                  result.
                  includes(:business).
                  order(id: :desc).
                  page(params[:page])
    end

    def show
    end

    def new
      @referral = Referral.new
      @referral.build_patient
    end

    def create
      @referral = Referral.new referral_params

      if @referral.valid?
        referral = Referral.create! referral_params.
                          except(:patient_attributes).
                          merge(patient_attrs: referral_params[:patient_attributes])

        AdminMailer.new_referral(referral).deliver_later!
        redirect_to admin_referrals_url,
                        notice: 'Referral has been created.'
      else
        render :new
      end
    end

    def assign_business
      @referral.assign_attributes params.require(:referral).permit(:business_id)
      @referral.status = Referral::STATUS_PENDING

      if !@referral.approved? && @referral.business && @referral.save
        @referral.businesses.delete_all
        @referral.businesses.push(@referral.business)

        redirect_to admin_referrals_path,
          notice: 'Business has been assigned.'
      else
        redirect_to admin_referrals_path,
          alert: 'Can\'t found business'
      end
    end

    def send_nearby_practitioners
      redirect_to admin_referrals_path, alert: 'This feature is suspsended.'

      return

      practitioners = Practitioner.approved.near(@referral.patient_address, 20, unit: :km)
                                  .where(profession: @referral.professions)
                                  .where("email IS NOT NULL")
      practitioners.each do |practitioner|
        PractitionerMailer.new_referral(@referral, practitioner).deliver_later!
        referrals = practitioner.business.referrals
        referrals.push(@referral) unless referrals.exists? @referral
      end

      @referral.update! status: Referral::STATUS_PENDING_MULTIPLE, business_id: nil

      redirect_to admin_referrals_path,
        notice: 'Referral has been send to nearby practitioners.'
    end

    def destroy
      @referral.destroy
      redirect_to admin_referrals_path,
                    notice: 'Referral has been deleted.'
    end

    private

    def set_referral
      @referral = Referral.find params[:id]
    end

    def referral_params
      params.require(:referral).permit(
        :availability_type_id, :practitioner_id,
        :referrer_business_name, :referrer_name, :referrer_email, :referrer_phone, :medical_note,
        patient_attributes: [
          :first_name, :last_name, :dob, :phone, :email, :address1, :city, :state,
          :postcode, :country
        ],
        attachments_attributes: [:attachment],
        professions: []
      )
    end
  end
end
