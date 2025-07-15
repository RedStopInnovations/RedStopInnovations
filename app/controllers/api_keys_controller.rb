class ApiKeysController < ApplicationController
  include HasABusiness

  def create
    @api_key = ApiKey.new(
      user_id: current_user.id,
      active: true
    )
    @api_key.token = ApiKey.generate_token
    @api_key.save!
  end

  def destroy
    @api_key = ApiKey.where(user_id: current_user.id).find(params[:id])
    @api_key.deactivate!
  end
end
