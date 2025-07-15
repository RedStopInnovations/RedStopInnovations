module App
  module DataExport
    class PatientLettersExportsController < ApplicationController
      include HasABusiness

      before_action do
        authorize! :export, :all
      end

      def index
        ahoy_track_once 'Use patient letters export'

        @exports = PatientLettersExport.where(business_id: current_business.id).order(id: :desc).page(params[:page])
      end

      def create
        ahoy_track_once 'Use patient letters export'

        @form = CreatePatientLettersExportForm.new(create_patient_letters_export_params.merge(
          business: current_business
        ))

        if @form.valid?
          reject_error = nil

          # Reject number of requests exceed the limitation within 24 hrs
          unless reject_error
            total_exports_24h = PatientLettersExport
              .where(business_id: current_business.id)
              .where('created_at >= ?', 24.hours.ago)
              .count

            if total_exports_24h >= 5
              reject_error = 'You can only create up to 5 exports within 24 hours.'
            end
          end

          # Creating export cooldown for 3 minutes
          unless reject_error
            last_pending_export_24h = PatientLettersExport
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
            pending_export_24h_count = PatientLettersExport
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
            CreatePatientLettersExportService.new.call(current_user, @form)
            flash[:notice] = 'The export is scheduled to start.'

            render(
              json: { success: true },
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
        ahoy_track_once 'Use patient letters export'

        @export = PatientLettersExport.where(business_id: current_business.id).find(params[:id])
      end

      def download
        ahoy_track_once 'Use patient letters export'

        export = PatientLettersExport.where(business_id: current_business.id).find(params[:id])
        redirect_to rails_blob_path(export.zip_file, disposition: "attachment", expires_in: 12.hours)
      end

      private

      def create_patient_letters_export_params
        params.permit(
          :start_date,
          :end_date,
          :description,
          template_ids: [],
        )
      end
    end
  end
end
