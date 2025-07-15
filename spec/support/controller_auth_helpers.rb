module ControllerAuthHelpers
  extend ActiveSupport::Concern
  included do
    let(:current_user) { FactoryBot.create(:user, :with_administrator_role) }
    let(:business) { current_user.business }
    let(:current_business) { current_user.business }
    before do |ex|
      # sign_out :user
      if ex.metadata[:authenticated]
        sign_in current_user
      end
    end
  end
end
