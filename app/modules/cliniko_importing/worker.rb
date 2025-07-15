module ClinikoImporting
  class Worker < ::ApplicationJob
    def perform(import_id)
      import = ClinikoImporting::Import.find(import_id)

      api_client = ClinikoApi::Client.new import.api_key
      import.status = ClinikoImporting::Import::STATUS_IN_PROGRESS
      import.started_at = Time.current
      import.save!

      case import.data_type
      when 'Patient'
        patients_collection = api_client.Patient.all
      when 'TreatmentNote'
      else
        raise NotImplementedError, "Import for #{import.data_type} is not implemented."
      end
    end
  end
end
