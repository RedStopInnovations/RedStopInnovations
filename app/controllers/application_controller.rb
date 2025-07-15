class ApplicationController < ActionController::Base
  COUNTRY_REDIRECT_EXCLUSIONS = [
    'app', 'admin', 'api', 'sitemap', 'embed',
    'ckeditor', 'capture', '_hooks', 'images', 'fonts',
    'webhook_subscriptions', 'stmtinv', 'documents', 'docs', '_trk', 'users/sign_out',
    'invoice-payment', 'reviews'
  ]

  protect_from_forgery with: :exception
  # before_action :country_redirect
  before_action :better_errors_fix, if: -> { Rails.env.development? }
  around_action :set_time_zone
  before_action :set_locale
  before_action :set_paper_trail_whodunnit

  helper_method :current_country

  if Rails.env.production?
    rescue_from StandardError do |e|
      if user_signed_in?
        Sentry.set_user(
          id: current_user.id,
          business_id: current_user.business_id
        )
      end
      Sentry.capture_exception(e)
      render_server_error
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      render_not_found
    end

    rescue_from ActionController::UnknownFormat do |e|
      render_not_found
    end

    rescue_from ActionController::InvalidAuthenticityToken do |e|
      message = 'There were an error due to session expiration.'\
                ' Please try again.'
      respond_to do |format|
        format.json {
          render(
            json: { error: message },
            status: 400
          )
        }
        format.html {
          redirect_back fallback_location: after_unauthorized_path, alert: message
        }
        format.js {
          head :bad_request, content_type: 'text/html'
        }
      end
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.json { head :forbidden, content_type: 'text/html' }
      format.html { redirect_to after_unauthorized_path, alert: exception.message }
      format.js   { head :forbidden, content_type: 'text/html' }
      format.csv  {
        redirect_to after_unauthorized_path, alert: exception.message
      }
    end
  end

  helper_method :current_business

  def current_business
    @current_business ||= current_user.try(:business)
  end

  def render_server_error
    respond_to do |f|
      f.json do
        render json: { message: 'Server errror' }, status: 500
      end
      f.html do
        render 'errors/500', layout: false, status: 500
      end
    end
  end

  def render_not_found
    respond_to do |f|
      f.json do
        render json: { error: 'Not found' } , status: :not_found
      end
      f.html do
        render 'errors/404', layout: false, status: :not_found
      end
      f.pdf do
        head :not_found
      end
    end
  end

  def info_for_paper_trail
    { ip: request.remote_ip, user_agent: request.user_agent }
  end

  protected

  def set_time_zone
    timezone =
      if user_signed_in?
        current_user.timezone
      else
        App::DEFAULT_TIME_ZONE
      end
    Time.use_zone(timezone) { yield }
  end

  def after_unauthorized_path
    if user_signed_in?
      dashboard_path
    else
      root_path
    end
  end

  private

  # Workaround for better_error page very slow to show the right panel
  def better_errors_fix
    request.env['puma.config'].options.user_options.delete :app
  end

  def default_url_options(options = {})
    if request.path.match(/^\/#{COUNTRY_REDIRECT_EXCLUSIONS.join('|')}\/*/).nil?
      options[:country] = params[:country]
    end
    options
  end

  def country_redirect
    countries = App::SUPPORT_COUNTRIES.map {|c| c.downcase}.join("|")

    if params[:country].nil? &&
      request.path.match(/^\/(#{countries})\//).nil? &&
      request.path.match(/^\/#{COUNTRY_REDIRECT_EXCLUSIONS.join('|')}\/*/).nil?

      country_code = Geocoder.search(request.remote_ip).first&.country_code.to_s.upcase
      country = ISO3166::Country.new(country_code)

      country_alpha2 = country&.alpha2 || App::DEFAULT_COUNTRY
      country_alpha2.gsub!(/GB/, 'UK')

      unless App::SUPPORT_COUNTRIES.include?(country_alpha2.upcase)
        country_alpha2 = App::DEFAULT_COUNTRY
      end

      redirect_to "/#{country_alpha2.downcase}" + request.fullpath, status: 301
    end
  end

  def current_country
    @current_country ||= begin
      code = params[:country] || App::DEFAULT_COUNTRY
      code = 'gb' if code == 'uk'
      code
    end.upcase
  end

  def set_locale
    # TODO: set locale for /app and frontend scopes seperately
    country =
      if user_signed_in? && request.path.match(/^\/app\/*/)
        current_business.country
      else
        current_country
      end
    locale = App::SUPPORT_LOCALES[country&.upcase] || App::DEFAULT_LOCALE

    I18n.locale = locale
  end

  def user_ip_country
    country_code = Geocoder.search(request.remote_ip).first&.country_code.to_s.upcase
    country_code.gsub(/GB/, 'UK')
  end

  # Track event once per visit, uniqueness by the name
  def ahoy_track_once(name, properties = {}, options = {})
    if current_visit && !current_visit.events.where(name: name).exists?
      ahoy.track name, properties, options
    end
  end
end
