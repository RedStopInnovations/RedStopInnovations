class PatientBulkArchiveRequestWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  def perform(request_id)
    request = PatientBulkArchiveRequest.pending.find_by(id: request_id)

    if request
      business = request.business

      request.status = PatientBulkArchiveRequest::STATUS_IN_PROGRESS
      request.save!

      archived_patient_ids = []

      begin
        filters = PatientBulkArchiveSearch::Filters.new request.filters.symbolize_keys
        searcher = PatientBulkArchiveSearch::Searcher.new(business, filters, request.created_at)

        patients = searcher.results

        patients.each do |patient|
          unless patient.archived_at?
            time = Time.current
            patient.update_columns(
              archived_at: time,
              updated_at: time
            )

            archived_patient_ids << patient.id
          end
        end

        request.status = PatientBulkArchiveRequest::STATUS_COMPLETED
      rescue => e
        request.status = PatientBulkArchiveRequest::STATUS_ERROR
        Sentry.capture_exception(e)
      ensure
        request.archived_patient_ids = archived_patient_ids.join(',')
        request.archived_patients_count = archived_patient_ids.count
        request.save
      end
    end
  end
end
