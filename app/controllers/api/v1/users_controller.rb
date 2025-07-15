module Api
  module V1
    class UsersController < V1::BaseController
      before_action :find_user, only: [:show]

      def index
        users = current_business.
          users.
          order(id: :asc).
          page(pagination_params[:number]).
          per(pagination_params[:size])

        render jsonapi: users,
               meta: pagination_meta(users)
      end

      def show
        render jsonapi: @user
      end

      private

      def find_user
        @user = current_business.users.find(params[:id])
      end
    end
  end
end
