class WebhookSubscriptionsController < ActionController::Base
  before_action :skip_session
  before_action :authorize_user
  before_action :better_errors_fix, if: -> { Rails.env.development? }
  # @see https://zapier.com/developer/documentation/v2/rest-hooks/
  def create
    ws = WebhookSubscription.new(
      user_id: api_user.id,
      business_id: api_user.business.id,
      active: true
    )

    ws.assign_attributes(subscribe_params)

    if ws.valid?
      ws.save!(validate: false)
      render(
        json: ws.to_json(only: [:id, :event, :target_url, :created_at]),
        status: 201
      )
    else
      render(
        json: {
          error: {
            message: "#{ws.errors.full_messages.join(', ')}",
            code: 'VALIDATION'
          }
        },
        status: 400
      )
    end
  end

  def destroy
    ws = WebhookSubscription.where(user_id: api_user.id).find(params[:id])
    ws.update_columns active: false
  end

  protected

  def subscribe_params
    params.permit(
      :event, :target_url
    )
  end

  def api_user
    @api_user
  end

  def authorize_user
    api_key = ApiKey.active.find_by(token: request_api_key)

    if api_key.present?
      @api_user = api_key.user
    else
      render_unauthorized
    end
  end

  def request_api_key
    request.headers['X-API-KEY']
  end

  def better_errors_fix
    request.env['puma.config'].options.user_options.delete :app
  end

  def skip_session
    request.session_options[:skip] = true
  end

  def render_unauthorized
      render(
        json: {
          error: {
            message: "#{ws.full_messages.join(', ')}",
            code: 'UNAUTHORIZED'
          }
        },
        status: 401
      )
  end
end
