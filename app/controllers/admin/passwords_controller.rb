module Admin
  class PasswordsController < Devise::PasswordsController
    layout 'admin_auth'
  end
end
