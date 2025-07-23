require 'csv'
require 'json'

namespace :splose do |args|
  # bin/rails splose:import_patient_other_info_csv business_id=1 csv=/path/to/file.csv
  task import_patient_other_info_csv: :environment do
    def log(what)
      puts what
    end

    def parse_json_array(json_string)
      return [] if json_string.blank?
      JSON.parse(json_string)
    rescue JSON::ParserError => e
      log "JSON parse error: #{e.message} for string: #{json_string}"
      []
    end

    business_id = ENV['business_id']
    csv_file_path = ENV['csv']
    @force_update = ENV['force_update'] == '1' || ENV['force_update'] == 'true'

    if business_id.blank? || csv_file_path.blank?
      raise ArgumentError, "Business ID or CSV file is missing! Usage: bin/rails splose:import_patient_other_info_csv business_id=1 csv=path/to/file.csv"
    end

    # Resolve relative path to absolute path from Rails root
    csv_file = File.absolute_path?(csv_file_path) ? csv_file_path : Rails.root.join(csv_file_path).to_s

    unless File.exist?(csv_file)
      raise ArgumentError, "CSV file not found: #{csv_file} (resolved from: #{csv_file_path})"
    end

    @business = Business.find(business_id)

    log "Business to process: ##{@business.id} - #{@business.name} | Patients: #{@business.patients.count}"

    @sync_start_at = Time.current
    log "Import starting: #{@sync_start_at.iso8601}. CSV file: #{csv_file}"

    @total = 0
    @total_updates = 0
    @total_skipped = 0
    @total_errors = 0

    begin
      CSV.foreach(csv_file, headers: true) do |row|
        @total += 1

        ActiveRecord::Base.transaction do
          begin
            # Extract CSV data
            splose_patient_id = row['ID']
            medications_json = row['Medications']
            allergies_json = row['Allergies']
            intolerances_json = row['Intolerances']

            if splose_patient_id.blank?
              log "Skipping row #{@total}: Missing Patient ID"
              @total_skipped += 1
              next
            end

            # Find the patient using splose_records
            patient_import_record = SploseRecord.find_by(
              business_id: @business.id,
              reference_id: splose_patient_id,
              resource_type: 'Patient'
            )

            unless patient_import_record
              log "Skipping row #{@total}: Patient not found for Splose ID #{splose_patient_id}"
              @total_skipped += 1
              next
            end

            patient = @business.patients.find(patient_import_record.internal_id)

            # Parse the JSON data
            medications = parse_json_array(medications_json)
            allergies = parse_json_array(allergies_json)
            intolerances = parse_json_array(intolerances_json)

            # Check if any of the fields have data or if force update is enabled
            has_new_data = medications.any? || allergies.any? || intolerances.any?
            has_existing_data = patient.medications.present? || patient.allergies.present? || patient.intolerances.present?

            if !@force_update && has_existing_data && !has_new_data
              log "Skipping row #{@total}: Patient #{patient.full_name} already has data and no new data to import"
              @total_skipped += 1
              next
            end

            if !has_new_data && !@force_update
              log "Skipping row #{@total}: No medication, allergy, or intolerance data for patient #{patient.full_name}"
              @total_skipped += 1
              next
            end

            # Prepare update attributes
            update_attrs = {}

            if medications.any? || @force_update
              update_attrs[:medications] = medications
            end

            if allergies.any? || @force_update
              update_attrs[:allergies] = allergies
            end

            if intolerances.any? || @force_update
              update_attrs[:intolerances] = intolerances
            end

            # Update patient with the new data
            if update_attrs.any?
              patient.update!(update_attrs)

              @total_updates += 1
              log "Updated patient #{patient.full_name} (ID: #{patient.id}, Splose ID: #{splose_patient_id})"
              log "  - Medications: #{medications.count} items" if medications.any?
              log "  - Allergies: #{allergies.count} items" if allergies.any?
              log "  - Intolerances: #{intolerances.count} items" if intolerances.any?
            else
              log "Skipping row #{@total}: No updates needed for patient #{patient.full_name}"
              @total_skipped += 1
            end

          rescue => e
            log "Error processing row #{@total}: #{e.message}"
            log "Patient ID: #{splose_patient_id}" if splose_patient_id.present?
            @total_errors += 1
            raise e # Re-raise to trigger transaction rollback
          end
        end

        # Log progress every 50 records
        if @total % 50 == 0
          log "Processed #{@total} records so far..."
        end
      end

    rescue => e
      log "Fatal error during import: #{e.message}"
      log e.backtrace.join("\n")
      raise e
    end

    @sync_end_at = Time.current
    duration = (@sync_end_at - @sync_start_at).round(2)

    log "Import completed in #{duration} seconds"
    log "Total processed: #{@total}"
    log "Updated: #{@total_updates}"
    log "Skipped: #{@total_skipped}"
    log "Errors: #{@total_errors}"

  end
end
