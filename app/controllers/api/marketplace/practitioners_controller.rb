module Api
  module Marketplace
    class PractitionersController < Api::Marketplace::BaseController
      def index
        @practitioners = Practitioner.
          within_marketplace(current_marketplace.id).
          includes(:user, :business)

        render(
          json: {
            practitioners: @practitioners.map do |p|
              Api::Marketplace::PractitionerSerializer.new(p)
            end
          }
        )
      end
    end
  end
end
