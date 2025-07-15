class ApplicationUploader < CarrierWave::Uploader::Base
  if Rails.env.production?
    storage :fog
  else
    storage :file
  end
end
