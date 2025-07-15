module Admin
  class InvitationsController < Devise::InvitationsController
    layout 'admin_auth'

    private

    def after_accept_path_for(user)
      admin_dashboard_path
    end
  end
end
