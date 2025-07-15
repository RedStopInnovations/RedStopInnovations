module App
  module DataExport
    class PatientAttachmentsExportsController < ApplicationController
      include HasABusiness

      before_action do
        authorize! :export, :all
      end

      def index
        @exports = PatientAttachmentExport.where(business_id: current_business.id).order(id: :desc).page(params[:page])
      end

      def create
        @form = CreatePatientAttachmentExportForm.new(create_export_params.merge(
          business: current_business
        ))

        if @form.valid?
          reject_error = nil

          # Reject if no attachments match
          exporter_options = Export::PatientAttachments::Options.new(
            @form.attributes.slice(
                *%i(start_date end_date patient_ids)
              )
            )

          exporter = Export::PatientAttachments.new(current_business, exporter_options)

          items_count = exporter.items_count

          if items_count == 0
            reject_error = 'There is no attachment that match the filters.'
          end

          # Reject number of requests exceed the limitation within 24 hrs
          unless reject_error
            total_exports_24h = PatientAttachmentExport
              .where(business_id: current_business.id)
              .where('created_at >= ?', 24.hours.ago)
              .count

            if total_exports_24h >= 5
              reject_error = 'You can only create up to 5 exports within 24 hours.'
            end
          end

          # Limit have a pending export within 3 minutes
          unless reject_error
            last_pending_export_24h = PatientAttachmentExport
              .where(business_id: current_business.id)
              .order(created_at: :desc)
              .where('created_at >= ?', 24.hours.ago)
              .pending
              .first

            if last_pending_export_24h && (Time.current - last_pending_export_24h.created_at) / 1.second <= 3 * 60
              reject_error = 'Please wait for 3 minutes before create new export.'
            end
          end

          # Limit 3 pending exports within 24 hour
          unless reject_error
            pending_export_24h_count = PatientAttachmentExport
              .where(business_id: current_business.id)
              .where('created_at >= ?', 24.hours.ago)
              .pending
              .count

            if pending_export_24h_count > 3
              reject_error = 'Too many exports are in progress. Please wait for them to finish before creating a new export.'
            end
          end

          if reject_error
            render(
              json: {message: 'Export request rejected: ' + reject_error },
              status: :bad_request
            )
          else
            CreatePatientAttachmentExportService.new.call(current_user, @form)
            flash[:notice] = 'The export is created. You will be notified when it\'s ready to download.'

            render(
              json: {success: true },
              status: :created
            )
          end
        else
          render(
            json: {errors: @form.errors },
            status: :unprocessable_entity
          )
        end
      end

      def show
        @export = PatientAttachmentExport.where(business_id: current_business.id).find(params[:id])
      end

      def download
        export = PatientAttachmentExport.where(business_id: current_business.id).find(params[:id])

        redirect_to rails_blob_path(export.zip_file, disposition: "attachment", expires_in: 12.hours)
      end

      private

      def create_export_params
        params.permit(
          :start_date,
          :end_date,
          :description,
          patient_ids: []
        )
      end
    end
  end
end
