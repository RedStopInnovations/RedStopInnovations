namespace :cliniko do |args|
  # bin/rails cliniko:import_treatment_templates business_id=xxx api_key=xxx api_shard=xxx
  task import_treatment_templates: :environment do
    class ImportTreatmentTemplate < ::ActiveRecord::Base
      self.table_name = 'treatment_templates'

      serialize :template_sections, type: Array
      belongs_to :business
      before_save do
        if template_sections.present?
          self.sections_count = template_sections.count
          self.questions_count = template_sections.map do |section|
            section[:questions].count
          end.reduce(&:+)
        else
          self.sections_count = 0
          self.questions_count = 0
        end
      end
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
    log "Sync started: #{@sync_start_at.iso8601}. Business ##{business_id} - #{@business.name}"

    @api_client = ClinikoApi::Client.new(api_key, api_shard)

    @total = 0
    @total_creations = 0
    @total_updates = 0
    @total_skips = 0

    api_res = @api_client.call(
      :get,
      "/treatment_note_templates?per_page=100"
    )
    treatment_templates = api_res['treatment_note_templates']
    log "Got #{treatment_templates.count} records."

    ActiveRecord::Base.transaction do
      treatment_templates.each do |raw_attrs|
        cliniko_treatment_tmpl = ClinikoApi::Resource::TreatmentTemplate.new
        cliniko_treatment_tmpl.attributes = raw_attrs

        import_record = ClinikoImporting::ImportRecord.find_or_initialize_by(
          business_id: @business.id,
          reference_id: cliniko_treatment_tmpl.id,
          resource_type: 'TreatmentTemplate'
        )

        if import_record.new_record?
          local_treatment_tmpl = ImportTreatmentTemplate.new(
            ClinikoImporting::Mapper::TreatmentTemplate.build(cliniko_treatment_tmpl)
          )
          local_treatment_tmpl.business_id = @business.id
          local_treatment_tmpl.save!

          import_record.internal_id = local_treatment_tmpl.id
          import_record.last_synced_at = @sync_start_at
          import_record.save!
          @total_creations += 1
        else
          # TODO: compare with updated_at on local record is better
          if cliniko_treatment_tmpl.updated_at > import_record.last_synced_at
            log "Cliniko treatment template ##{cliniko_treatment_tmpl.id} has new update."
            local_treatment_tmpl = ImportTreatmentTemplate.find_by(
              id: import_record.internal_id
            )
            if local_treatment_tmpl.nil? # Synced but deleted later
              local_treatment_tmpl = ImportTreatmentTemplate.new
              @total_creations += 1
            else
              @total_updates += 1
            end

            local_treatment_tmpl.assign_attributes(
              ClinikoImporting::Mapper::TreatmentTemplate.build(cliniko_treatment_tmpl)
            )
            local_treatment_tmpl.save!
            import_record.internal_id = local_treatment_tmpl.id
            import_record.last_synced_at = @sync_start_at
            import_record.save!
          else
            log "Skip. Cliniko treatment template ##{cliniko_treatment_tmpl.id} is up to date."
            @total_skips += 1
          end
        end
      end
    end

    @total += treatment_templates.count

    log "Sync finished:"
    log "Total:     #{@total}"
    log "Creations: #{@total_creations}"
    log "Updates:   #{@total_updates}"
    log "Skips:     #{@total_skips}"
    log "Time:      #{(Time.current - @sync_start_at).round(1)} secs"
  end
end
