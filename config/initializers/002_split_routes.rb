route_files = Dir[Rails.root.join("config/routes/**/*.rb").to_s]
Rails.application.routes_reloader.paths.unshift *route_files
Rails.application.config.paths["config/routes.rb"].concat route_files
