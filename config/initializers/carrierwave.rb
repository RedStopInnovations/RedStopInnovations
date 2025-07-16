require 'carrierwave/storage/abstract'
require 'carrierwave/storage/file'
require 'carrierwave/storage/fog'

CarrierWave.configure do |config|
  config.fog_credentials = {
    provider:              'AWS',
    aws_access_key_id:     ENV.fetch('AWS_ACCESS_KEY_ID', 'xxx'),
    aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', 'xxx'),
    region:                ENV.fetch('AWS_REGION', 'ap-southeast-2'),
  }
  config.fog_directory  = ENV.fetch('S3_BUCKET_NAME', 'mybucket')
  config.fog_public     = true
  config.fog_attributes = { 'Cache-Control' => "max-age=#{365.day.to_i}" }
end
