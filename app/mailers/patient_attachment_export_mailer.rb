class PatientAttachmentExportMailer < ApplicationMailer
  def export_download_ready_mail(export)
    @author = export.author
    @export = export
    mail to: @author.email, subject: 'Client attachments export is ready to download'
  end
end