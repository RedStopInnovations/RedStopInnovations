namespace :cliniko do |args|
  # For business which has practitioners imported from Cliniko
  task import_treatment_notes_2: :environment do
    class ImportTreatmentNote < ::ActiveRecord::Base
      self.table_name = 'treatment_nots'

      serialize :sections, type: Array
    end

    def log(what)
      puts "[CLINIKO_IMPORT] #{what}"
    end

    business_id = ENV['business_id']
    api_key = ENV['api_key']
    if business_id.blank? || api_key.blank?
      raise ArgumentError, "Business ID or API key is missing!"
    end

    @business = Business.find(business_id)

    @sync_start_at = Time.current
    log "Sync started: #{@sync_start_at.iso8601}. Business ##{business_id} - #{@business.name}"

    @api_client = ClinikoApi::Client.new(api_key)

    # Test api key
    @api_client.call(:get, '/users?per_page=1')

    @import_practitioners = ClinikoImporting::ImportRecord.where(
      business_id: @business.id,
      resource_type: 'Practitioner'
    ).to_a

    @total = 0
    @total_creations = 0
    @total_updates = 0
    @total_skips = 0

    @practitioner_reference_ids = @import_practitioners.map(&:reference_id)

    if @practitioner_reference_ids.empty?
      log 'ABORTED. No any practitioner matched.'
      abort
    end

    url = "/treatment_notes?q[]=practitioner_id:=#{@practitioner_reference_ids.join(',')}&per_page=100"

    loop do
      res = @api_client.call(
        :get,
        url
      )
      treatment_notes = res['treatment_notes']
      log "Got #{treatment_notes.count} records."

      treatment_notes.each do |raw_attrs|
        cliniko_treatment = ClinikoApi::Resource::TreatmentNote.new
        cliniko_treatment.attributes = raw_attrs
        treatment_template_reference_id = cliniko_treatment.treatment_note_template['links']['self'].split('/').last
        parsed_patient_reference_id = cliniko_treatment.patient['links']['self'].split('/').last
        parsed_pract_reference_id = cliniko_treatment.practitioner['links']['self'].split('/').last
        import_patient = ClinikoImporting::ImportRecord.find_by(
          business_id: @business.id,
          reference_id: parsed_patient_reference_id,
          resource_type: 'Patient'
        )

        import_practitioner = ClinikoImporting::ImportRecord.find_by(
          business_id: @business.id,
          reference_id: parsed_pract_reference_id,
          resource_type: 'Practitioner'
        )

        import_templ = ClinikoImporting::ImportRecord.find_by(
          business_id: @business.id,
          reference_id: treatment_template_reference_id,
          resource_type: 'TreatmentTemplate'
        )

        if import_patient.nil? || import_practitioner.nil?
          log "Skip. Practitioner or patient is not imported."
          @total_skips += 1
          next
        end

        import_treatment_note = ClinikoImporting::ImportRecord.new(
          business_id: @business.id,
          reference_id: cliniko_treatment.id,
          resource_type: 'TreatmentNote'
        )

        if import_treatment_note.new_record?
          local_treatment = ImportTreatmentNote.new(
            ClinikoImporting::Mapper::TreatmentNote.build(cliniko_treatment)
          )
          local_treatment.patient_id = import_patient.internal_id
          local_treatment.practitioner_id = import_practitioner.internal_id
          # Map treatment template if existing
          if import_templ
            local_treatment.treatment_template_id = import_templ.internal_id
          end
          local_treatment.save!

          import_treatment_note.internal_id = local_treatment.id
          import_treatment_note.last_synced_at = @sync_start_at
          import_treatment_note.save!
          @total_creations += 1

        else
          # TODO: compare with updated_at on local record is better
          if cliniko_treatment.updated_at > import_treatment_note.last_synced_at
            log "Cliniko treatment note ##{cliniko_treatment.id} has new update."
            local_treatment = ImportTreatmentNote.find_by(
              id: import_treatment_note.internal_id
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
            local_treatment.save!
            import_treatment_note.internal_id = local_treatment.id
            import_treatment_note.last_synced_at = @sync_start_at
            import_treatment_note.save!
          else
            log "Skip. Cliniko treatment note ##{cliniko_treatment.id} is up to date."
            @total_skips += 1
          end
        end
      end

      @total += treatment_notes.count

      if res['links']['next'].present?
        url = res['links']['next']
      else
        break
      end
    end

    log "Sync finished:"
    log "Total:     #{@total}"
    log "Creations: #{@total_creations}"
    log "Updates:   #{@total_updates}"
    log "Skips:     #{@total_skips}"
    log "Time:      #{(Time.current - @sync_start_at).round(1)} secs"
  end
end
