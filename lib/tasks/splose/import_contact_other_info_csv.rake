require 'csv'
require 'json'

namespace :splose do |args|
  # bin/rails splose:import_contact_other_info_csv business_id=1 csv=/path/to/file.csv
  task import_contact_other_info_csv: :environment do
    def log(what)
      puts what
    end

    business_id = ENV['business_id']
    csv_file_path = ENV['csv']

    if business_id.blank? || csv_file_path.blank?
      raise ArgumentError, "Business ID or CSV file is missing! Usage: bin/rails splose:import_contact_other_info_csv business_id=1 csv=path/to/file.csv"
    end

    # Resolve relative path to absolute path from Rails root
    csv_file = File.absolute_path?(csv_file_path) ? csv_file_path : Rails.root.join(csv_file_path).to_s

    unless File.exist?(csv_file)
      raise ArgumentError, "CSV file not found: #{csv_file} (resolved from: #{csv_file_path})"
    end

    @business = Business.find(business_id)

    log "Business to process: ##{@business.id} - #{@business.name} | Contacts: #{@business.contacts.count}"

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
            splose_contact_id = row['ID']
            notes = row['Notes']

            if splose_contact_id.blank?
              log "Skipping row #{@total}: Missing Contact ID"
              @total_skipped += 1
              next
            end

            # Find the contact using splose_records
            contact_import_record = SploseRecord.find_by(
              business_id: @business.id,
              reference_id: splose_contact_id,
              resource_type: 'Contact'
            )

            unless contact_import_record
              log "Skipping row #{@total}: Contact not found for Splose ID #{splose_contact_id}"
              @total_skipped += 1
              next
            end

            contact = @business.contacts.find(contact_import_record.internal_id)

            update_attrs = {
              notes: notes.presence
            }

            contact.assign_attributes(update_attrs)
            contact.save!(validate: false)

            @total_updates += 1
            log "Updated contact #{contact.business_name} (ID: #{contact.id}, Splose ID: #{splose_contact_id})"
          rescue => e
            log "Error processing row #{@total}: #{e.message}"
            log "Contact ID: #{splose_contact_id}" if splose_contact_id.present?
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
