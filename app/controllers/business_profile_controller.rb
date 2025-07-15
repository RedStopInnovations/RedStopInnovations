class BusinessProfileController < ApplicationController
  include HasABusiness

  before_action do
    authorize! :edit, :business_profile
  end

  def edit
    @business = current_business.clone
  end

  def update
    @business = current_business.clone

    if @business.update(update_params)
      changes = @business.previous_changes.symbolize_keys.slice(*%i(bank_branch_number bank_account_name bank_account_number))

      if changes.present?
        BusinessMailer.bank_account_details_updated(@business, current_user, Time.current.to_i).deliver_later
      end

      redirect_to edit_business_profile_url,
        notice: 'The business profile was successfully updated.'
    else
      flash.now[:alert] = 'Failed to update information. Please check for form errors.'
      render :edit
    end
  end

  private

  def update_params
    params.require(:business).permit(
      :name,
      :phone,
      :mobile,
      :website,
      :fax,
      :email,
      :accounting_email,
      :address1,
      :address2,
      :city,
      :state,
      :postcode,
      :country,
      :avatar,
      :abn,
      :bank_name,
      :bank_branch_number,
      :bank_account_name,
      :bank_account_number,
      :policy_url
    )
  end
end
