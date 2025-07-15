module App
  class PatientBulkArchiveController < ApplicationController
    include HasABusiness

    before_action do
      authorize! :manage, Patient
    end

    def index
    end

    def search
      filters = PatientBulkArchiveSearch::Filters.new search_params.to_unsafe_h
      searcher = PatientBulkArchiveSearch::Searcher.new(current_business, filters, Time.current)

      @patients = searcher.paginated_results
    end

    def requests
      @requests = PatientBulkArchiveRequest
        .where(business_id: current_business)
        .includes(:author)
        .order(id: :desc)
    end

    def create_request
      @form = PatientBulkArchiveRequestForm.new(create_bulk_archive_request_params.merge(
        business: current_business
      ))

      if @form.valid?
        reject_error = nil

        # Check to reject if no clients match
        filters = PatientBulkArchiveSearch::Filters.new search_params.to_unsafe_h
        searcher = PatientBulkArchiveSearch::Searcher.new(current_business, filters, Time.current)
        patients_count = searcher.results_count
        if patients_count == 0
          reject_error = 'There is no clients that match the criteria.'
        end

        # Reject there is another pending requests
        unless reject_error
          not_finished_requests_count = PatientBulkArchiveRequest
            .not_finished
            .where(business_id: current_business.id)
            .count

          if not_finished_requests_count > 0
            reject_error = 'There is another bulk archive process is not finished.'
          end
        end

        if reject_error
          render(
            json: {message: 'Error: ' + reject_error },
            status: :bad_request
          )
        else
          CreatePatientBulkArchiveRequestService.new.call(current_user, @form)
          flash[:notice] = 'The bulk archive has been started.'

          render(
            json: { success: true },
            status: :created
          )
        end
      else
        render(
          json: { errors: @form.errors.full_messages },
          status: :unprocessable_entity
        )
      end
    end

    def create_bulk_archive_request_params
      params.permit(
        :contact_id,
        :create_date_from,
        :create_date_to,
        :no_appointment_period,
        :no_invoice_period,
        :no_treatment_note_period,
        :description
      )
    end

    def search_params
      params.permit(
        :contact_id,
        :create_date_from,
        :create_date_to,
        :no_appointment_period,
        :no_invoice_period,
        :no_treatment_note_period,
        :page,
        :per_page
      )
    end
  end
end