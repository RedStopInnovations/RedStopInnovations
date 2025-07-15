class PractitionerDocumentUploader < CarrierWave::Uploader::Base

  before :cache, :save_original_filename

  if Rails.env.production?
    storage :fog
  else
    storage :file
  end

  def store_dir
    "uploads/practitioner_documents/#{model.practitioner_id}"
  end

  def filename
    "#{secure_token}.#{file.extension}" if original_filename.present?
  end

  def save_original_filename(file)
    model.document_original_filename ||= sanitize_filename(file.original_filename) if file.respond_to?(:original_filename)
  end

  protected

  def secure_token
    var = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(var) or model.instance_variable_set(var, SecureRandom.uuid)
  end

  def sanitize_filename(name)
    name.gsub(/^.*(\\|\/)/, '').gsub(/[^0-9A-Za-z.\-]/, '_')
  end
end
