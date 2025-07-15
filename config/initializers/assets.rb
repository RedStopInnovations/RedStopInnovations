Rails.application.config.assets.version = '1.3'

Rails.application.config.assets.precompile += %w(
  application.js
  application.css
  iframe.css
  print.css
  application-vendors.css
  application-vendors.js
  iframe.js
)

Rails.application.config.assets.precompile << /\.(?:svg|eot|woff|ttf)\z/

Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'plugins')

Rails.application.config.assets.precompile += %w(
  letter-pdf.css
  wait-list-pdf.css
  daily-appointments-schedule-pdf.css
  pdf/account-statement.css
  pdf/treatment-note.css
  pdf/invoice.css
)
Rails.application.config.assets.precompile += []
# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')