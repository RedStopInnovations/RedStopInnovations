module Reports
  class AttendanceProofExportsController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :read, :reports
    end

    def index
      ahoy_track_once 'View appointment proof of attendance report'

      @exports = AttendanceProofExport.where(business_id: current_business.id).order(id: :desc).page(params[:page])
    end

    def create
      form_request = CreateAttendanceProofExportForm.new(create_export_params.merge(
        business: current_business
      ))

      if form_request.valid?
        reject_error = nil

        # Reject if no appointment match
        exporter_options = Export::AttendanceProof::Options.new(
          form_request.attributes.slice(
              *%i(invoice_id account_statement_id)
            )
          )
        exporter = Export::AttendanceProof.new(current_business, exporter_options)
        appointments_count = exporter.items_count

        if appointments_count == 0
          reject_error = 'There is no appointments that match your search.'
        end

        if reject_error
          flash[:alert] = 'Export request rejected: ' + reject_error

          redirect_to reports_attendance_proof_exports_path
        else
          CreateAttendanceProofExportService.new.call(current_user, form_request)
          flash[:notice] = 'The export is created. You will be notified when it\'s ready to download.'

          redirect_to reports_attendance_proof_exports_path
        end
      else
        redirect_to reports_attendance_proof_exports_path, alert: form_request.errors.full_messages.first
      end
    end

    def show
      @export = AttendanceProofExport.where(business_id: current_business.id).find(params[:id])
    end

    def download
      export = AttendanceProofExport.where(business_id: current_business.id).find(params[:id])
      redirect_to rails_blob_path(export.zip_file, disposition: "attachment", expires_in: 12.hours)
    end

    private

    def create_export_params
      params.permit(
        :invoice_id,
        :account_statement_id,
        :description
      )
    end
  end
end
