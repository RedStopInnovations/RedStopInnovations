# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
Mime::Type.register "application/pdf", :pdf
Mime::Type.register 'application/vnd.api+json', :json, %W(
  application/vnd.api+json
  text/x-json
  application/json
)
