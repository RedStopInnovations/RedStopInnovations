require 'csv'

namespace :splose do |args|
  # bin/rails splose:import_letters_csv business_id=1 csv=/path/to/file.csv
  task import_letters_csv: :environment do
    class SploseImportRecord < ActiveRecord::Base
      self.table_name = 'splose_records'
    end

    class ImportPatientLetter < ::ActiveRecord::Base
      self.table_name = 'patient_letters'
    end

    def log(what)
      puts "[SPLOSE_IMPORT] #{what}"
    end

    business_id = ENV['business_id']
    csv_file_path = ENV['csv']
    @force_update = ENV['force_update'] == '1' || ENV['force_update'] == 'true'

    if business_id.blank? || csv_file_path.blank?
      raise ArgumentError, "Business ID or CSV file is missing! Usage: bin/rails splose:import_letters_csv business_id=1 csv=path/to/file.csv"
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
    @total_creations = 0
    @total_updates = 0
    @total_skipped = 0
    @total_errors = 0

    begin
      CSV.foreach(csv_file, headers: true) do |row|
        @total += 1

        ActiveRecord::Base.transaction do
          begin
            # Extract CSV data
            splose_letter_id = row['ID']
            title = row['Title']
            splose_patient_id = row['Patient ID']
            content = row['Content']

            if splose_letter_id.blank? || splose_patient_id.blank?
              log "Skipping row #{@total}: Missing ID or Patient ID"
              @total_skipped += 1
              next
            end

            # Find the patient using splose_records
            patient_import_record = SploseImportRecord.find_by(
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

            # Check if letter already exists in splose_records
            letter_import_record = SploseImportRecord.find_or_initialize_by(
              business_id: @business.id,
              reference_id: splose_letter_id,
              resource_type: 'PatientLetter'
            )

            if letter_import_record.persisted? && !@force_update
              log "Skipping row #{@total}: Letter already imported (ID: #{splose_letter_id})"
              @total_skipped += 1
              next
            end

            # Create or update patient letter
            if letter_import_record.new_record?
              # Create new letter
              patient_letter = PatientLetter.new(
                patient_id: patient.id,
                business_id: @business.id,
                # author_id: @business.practitioners.first&.id, # Use first practitioner as default
                description: title.present? ? title.truncate(255) : 'Imported Letter',
                content: content.present? ? content : 'No content available'
              )

              if patient_letter.save
                letter_import_record.internal_id = patient_letter.id
                letter_import_record.last_synced_at = @sync_start_at
                letter_import_record.save!

                @total_creations += 1
                log "Created letter #{patient_letter.id} for patient #{patient.full_name} (Splose ID: #{splose_letter_id})"
              else
                log "Failed to create letter for Splose ID #{splose_letter_id}: #{patient_letter.errors.full_messages.join(', ')}"
                @total_errors += 1
              end
            else
              # Update existing letter
              patient_letter = PatientLetter.find(letter_import_record.internal_id)
              patient_letter.update!(
                description: title.present? ? title.truncate(255) : patient_letter.description,
                content: content.present? ? content : patient_letter.content
              )

              letter_import_record.last_synced_at = @sync_start_at
              letter_import_record.save!

              @total_updates += 1
              log "Updated letter #{patient_letter.id} for patient #{patient.full_name} (Splose ID: #{splose_letter_id})"
            end

          rescue => e
            log "Error processing row #{@total}: #{e.message}"
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
    log "Created: #{@total_creations}"
    log "Updated: #{@total_updates}"
    log "Skipped: #{@total_skipped}"
    log "Errors: #{@total_errors}"

  end
end