wkhtmltopdf_path = ENV.fetch('WKHTMLTOPDF_PATH', '/usr/local/bin/wkhtmltopdf')
WickedPdf.config = {
  exe_path: wkhtmltopdf_path
}