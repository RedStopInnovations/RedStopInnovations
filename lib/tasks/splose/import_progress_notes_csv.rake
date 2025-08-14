require 'csv'
require Rails.root.join 'lib/helpers/prose_mirror'

namespace :splose do
  # bin/rails splose:import_progress_notes_csv business_id=1 csv=/path/to/file.csv
  task import_progress_notes_csv: :environment do
    class ImportTreatmentNote < ::ActiveRecord::Base
      self.table_name = 'treatment_notes'
    end

    def log(what)
      puts what
    end

    business_id = ENV['business_id']
    csv_file_path = ENV['csv']
    @force_update = ENV['force_update'] == '1' || ENV['force_update'] == 'true'

    if business_id.blank? || csv_file_path.blank?
      raise ArgumentError, "Business ID or CSV file is missing! Usage: bin/rails splose:import_progress_notes_csv business_id=1 csv=path/to/file.csv"
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
            splose_note_id = row['ID']
            title = row['Title']
            splose_patient_id = row['Patient ID']
            draft = row['Draft']
            content = row['Content']

            if splose_note_id.blank? || splose_patient_id.blank?
              log "Skipping row #{@total}: Missing ID or Patient ID"
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

            # Map draft status
            status = case draft&.strip&.downcase
                     when 'yes', 'true', '1'
                       TreatmentNote::STATUS_DRAFT
                     else
                       TreatmentNote::STATUS_FINAL
                     end

            # Parse and convert JSON content to HTML
            html_content =
            if content.present?
              doc_json = JSON.parse(content)
              if doc_json['type'] == 'doc' && doc_json['content'].is_a?(Array)
                # Convert the content array to HTML using ProseMirror
                Helpers::ProseMirror.serialize_doc(doc_json['content'])
              else
                # Fallback to plain content if structure is unexpected
                cleaned_content.split("\n").map { |line| "<p>#{line}</p>" }.join
              end
            else
              nil
            end

            # Check if treatment already exists in splose_records
            treatment_import_record = SploseRecord.find_or_initialize_by(
              business_id: @business.id,
              reference_id: splose_note_id,
              resource_type: 'TreatmentNote'
            )

            if treatment_import_record.persisted? && !@force_update
              log "Skipping row #{@total}: Treatment already imported (ID: #{splose_note_id})"
              @total_skipped += 1
              next
            end

            # Create or update treatment
            if treatment_import_record.new_record?
              # Create new treatment
              treatment = Treatment.new(
                patient_id: patient.id,
                name: title.present? ? title : 'Imported progress note from Splose',
                status: status,
                content: content,
                html_content: html_content
              )

              if treatment.save(validate: false) # Skip validations to avoid required field issues
                treatment_import_record.internal_id = treatment.id
                treatment_import_record.last_synced_at = @sync_start_at
                treatment_import_record.save!

                @total_creations += 1
                log "Created treatment #{treatment.id} for patient #{patient.full_name} (Splose ID: #{splose_note_id})"
              else
                log "Failed to create treatment for Splose ID #{splose_note_id}: #{treatment.errors.full_messages.join(', ')}"
                @total_errors += 1
              end
            else
              # Update existing treatment
              treatment = Treatment.find(treatment_import_record.internal_id)
              treatment.update!(
                name: title.present? ? title : treatment.name,
                status: status,
                content: content,
                html_content: html_content
              )

              treatment_import_record.last_synced_at = @sync_start_at
              treatment_import_record.save!

              @total_updates += 1
              log "Updated treatment #{treatment.id} for patient ##{patient.id} #{patient.full_name} (Splose ID: #{splose_note_id})"
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