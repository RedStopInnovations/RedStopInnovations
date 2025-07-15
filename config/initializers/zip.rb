# @see: https://github.com/rubyzip/rubyzip/tree/v2.3.2?tab=readme-ov-file#block-form
Zip.setup do |c|
  c.on_exists_proc = true
  c.write_zip64_support = true
  c.unicode_names = true
  c.default_compression = Zlib::BEST_COMPRESSION
end
