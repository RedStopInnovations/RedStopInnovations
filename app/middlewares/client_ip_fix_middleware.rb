class ClientIpFixMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['HTTP_X_FORWARDED_FOR']
      real_ip = env['HTTP_X_FORWARDED_FOR'].split(',').first
      env['REMOTE_ADDR'] = real_ip
      env['HTTP_X_FORWARDED_FOR'] = real_ip
    end
    @app.call(env)
  end
end