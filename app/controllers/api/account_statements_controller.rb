module Api
  class AccountStatementsController < BaseController
    def search
      keyword = params[:s].to_s.presence

      @account_statements = current_business.account_statements.
            ransack(number_cont: keyword).
            result.
            includes(:source).
            limit(10).
            order(id: :desc)

      render json: {
        account_statements: @account_statements.as_json(include: :source)
      }
    end
  end
end
