Paperclip::Attachment.default_options[:validate_media_type] = false
Paperclip::Attachment.default_options[:use_timestamp] = false

# Setting for Paperclip storage
if Rails.env.development?
  # Use file system storage for delopment
  {
    url: "/uploads/:class/:id/:attachment/:style/:filename",
    path: ':rails_root/public/uploads/:class/:id/:attachment/:style/:filename'
  }
elsif Rails.env.test?
  # Separate storage for testing to purge after test suite.
  {
    url: "/uploads/:class/:id/:attachment/:style/:filename",
    path: ':rails_root/public/uploads_test/:class/:id/:attachment/:style/:filename'
  }
elsif Rails.env.production?
  # AWS S3
  {
    storage: :s3,
    s3_credentials: {
      access_key_id:     ENV.fetch('AWS_ACCESS_KEY_ID', 'xxx'),
      secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', 'xxx'),
      s3_region:         ENV.fetch('AWS_REGION', 'us-southeast-2'),
    },
    url: ':s3_alias_url',
    s3_protocol: :https,
    s3_host_alias: ENV.fetch('S3_HOST_ALIAS', 'mybucket.s3.amazonaws.com'),
    bucket: ENV.fetch('S3_BUCKET_NAME', 'mybucket'),
    path: '/uploads/:class/:id/:attachment/:style/:filename'
  }
else
  raise "Not found Paperclip setting for current Rails environment!"
end.each do |k, v|
  Paperclip::Attachment.default_options[k] = v
end
