module PatientAttachmentsHelper
  # Font-Awesome class for file types
  # @see http://fontawesome.io/icons/#file-type
  def icon_class_for_attachment_content_type(attachment_content_type)
    case attachment_content_type
    when /\Aimage\/.*\Z/
      'fa-file-image-o'
    when 'application/pdf'
      'fa-file-pdf-o'
    else
      'fa-file-o'
    end
  end

  def default_attachment_email_message_to_contacts(attachment)
    "Please find attached #{@attachment.attachment_file_name}."
  end
end
