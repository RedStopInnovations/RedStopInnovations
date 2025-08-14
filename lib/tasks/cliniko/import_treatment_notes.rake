namespace :cliniko do |args|
  # bin/rails cliniko:import_treatment_notes business_id=xxx api_key=xxx api_shard=xxx
  task import_treatment_notes: :environment do
    class ImportTreatmentNote < ::ActiveRecord::Base
      self.table_name = 'treatment_notes'
    end

    def log(what)
      puts "[CLINIKO_IMPORT] #{what}"
    end

    business_id = ENV['business_id']
    api_key = ENV['api_key']
    api_shard = ENV['api_shard']

    if business_id.blank? || api_key.blank?
      raise ArgumentError, "Business ID or API key is missing!"
    end

    @business = Business.find(business_id)

    log "Business to processed: ##{@business.name} | Users: #{@business.users.count} | Patients: #{@business.patients.count} | Created: #{@business.created_at.strftime('%Y-%m-%d')}"
    print "Type \"OK\" to continue: "
    continue_confirm = STDIN.gets.chomp
    if continue_confirm != 'OK'
      log "Cancelled due to not confirmed"
      exit(0)
    end

    @sync_start_at = Time.current
    log "Sync starting: #{@sync_start_at.iso8601}. Business ##{business_id} - #{@business.name}"

    @api_client = ClinikoApi::Client.new(api_key, api_shard)

    @total = 0
    @total_creations = 0
    @total_updates = 0
    @total_skips = 0

    def fetch_treatment_notes(url = '/treatment_notes')
      log "Fetching treatment notes ... "
      res = @api_client.call(:get, url, per_page: 100)
      treatment_notes = res['treatment_notes']
      log "Got: #{treatment_notes.count} records."

      treatment_notes.each do |raw_attrs|
        cliniko_treatment = ClinikoApi::Resource::TreatmentNote.new
        cliniko_treatment.attributes = raw_attrs

        imported_patient = ClinikoImporting::ImportRecord.find_by(
          business_id: @business.id,
          resource_type: 'Patient',
          reference_id: cliniko_treatment.parse_patient_id
        )

        if !imported_patient
          log "[SKIPPED] Not found imported patient for treatment note ref ID ##{cliniko_treatment.id}"
          @total_skips +=1
          next
        end

        local_author = @business.
          users.
          find_by(
            'LOWER(full_name) = ?', cliniko_treatment.author_name.downcase
          )

        import_record = ClinikoImporting::ImportRecord.find_or_initialize_by(
          business_id: @business.id,
          reference_id: cliniko_treatment.id,
          resource_type: 'TreatmentNote'
        )

        # Find the corresponding imported template
        cliniko_template_import_record = ClinikoImporting::ImportRecord.find_by(
          business_id: @business.id,
          resource_type: 'TreatmentTemplate',
          reference_id: cliniko_treatment.parse_treatment_note_template_id
        )

        if cliniko_template_import_record
          local_template_id = cliniko_template_import_record.internal_id
        end

        local_template_id = nil

        ActiveRecord::Base.transaction do
          if import_record.new_record?
            local_treatment = ImportTreatmentNote.new(
              ClinikoImporting::Mapper::TreatmentNote.build(cliniko_treatment)
            )
            local_treatment.patient_id = imported_patient.internal_id
            local_treatment.author_id = local_author&.id
            local_treatment.treatment_template_id = local_template_id
            local_treatment.save!

            import_record.internal_id = local_treatment.id
            import_record.last_synced_at = @sync_start_at
            import_record.save!
            @total_creations += 1
          else
            # TODO: compare with updated_at on local record is better
            if cliniko_treatment.updated_at > import_record.last_synced_at
              log "Cliniko treatment note ##{cliniko_treatment.id} has new update."
              local_treatment = ImportTreatmentNote.find_by(
                id: import_record.internal_id
              )
              if local_treatment.nil? # Synced but deleted later
                local_treatment = ImportTreatmentNote.new
                @total_creations += 1
              else
                @total_updates += 1
              end

              local_treatment.assign_attributes(
                ClinikoImporting::Mapper::TreatmentNote.build(cliniko_treatment)
              )
              local_treatment.treatment_template_id = local_template_id
              local_treatment.save!
              import_record.internal_id = local_treatment.id
              import_record.last_synced_at = @sync_start_at
              import_record.save!
            else
              log "Cliniko treatment note ##{cliniko_treatment.id} is up to date. SKIPPED"
            end
          end
        end
      end

      if res['links']['next'].present?
        sleep(5)
        fetch_treatment_notes(res['links']['next'])
      end
    end

    fetch_treatment_notes

    log "Sync finished:"
    log "Total:     #{@total}"
    log "Creations: #{@total_creations}"
    log "Updates:   #{@total_updates}"
    log "Skips:     #{@total_skips}"
    log "Time:      #{(Time.current - @sync_start_at).round(1)} secs"
  end
end
