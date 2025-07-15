class AttendanceProofExportMailer < ApplicationMailer
  def export_download_ready_mail(export)
    @author = export.author
    @export = export
    mail to: @author.email, subject: 'Proof of attendance export is ready to download'
  end
end