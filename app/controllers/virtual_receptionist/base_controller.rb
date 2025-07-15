module VirtualReceptionist
  class BaseController < ApplicationController
    include HasABusiness

    before_action :authenticate_virtual_receptionist_user

    private

    def authenticate_virtual_receptionist_user
      unless current_user.role_virtual_receptionist?

        respond_to do |f|
          f.html do
            redirect_to dashboard_url, alert: 'Virtual receptionist only'
          end

          f.json do
            render json: { error: 'Unauthorized' }, status: :forbidden
          end
        end
      end
    end
  end
end
