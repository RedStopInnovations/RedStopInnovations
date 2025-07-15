wkhtmltopdf_path = ENV.fetch('WKHTMLTOPDF_PATH', '/usr/bin/wkhtmltopdf')
WickedPdf.config = {
  exe_path: wkhtmltopdf_path
}