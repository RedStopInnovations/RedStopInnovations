# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  :password, :api_key, :token, :stripeToken, :stripe_token, :data_url, :passw, :secret, :_key, :crypt, :salt, :certificate, :otp, :ssn
]
