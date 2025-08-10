namespace :splose do |args|
  # bin/rails splose:import_patients business_id=1 api_key=xxx force_update=1 splose_base_url=https://tbu.splose.com
  task import_patients: :environment do
    @patient_tags = []
    @splose_base_url = nil

    def map_patient_attrs(splose_attrs)
      internal_attrs = {}

      internal_attrs[:title] = splose_attrs['title'].presence
      internal_attrs[:first_name] = splose_attrs['firstname'].presence
      internal_attrs[:last_name] = splose_attrs['lastname'].presence
      internal_attrs[:middle_name] = splose_attrs['middleName'].presence
      internal_attrs[:dob] = splose_attrs['birthdate'].presence
      internal_attrs[:gender] = splose_attrs['sex'].presence
      internal_attrs[:email] = splose_attrs['email'].presence
      internal_attrs[:timezone] = splose_attrs['timezone'].presence

      internal_attrs[:important_notification] = splose_attrs['alert'].presence
      internal_attrs[:extra_invoice_info] = splose_attrs['extraBillingInfo'].strip.presence

      internal_attrs[:accepted_privacy_policy] =
        if splose_attrs['privacyPolicy'].present?
          {
            'Accepted' => true,
            'Rejected' => false,
            'No response' => nil
          }[splose_attrs['privacyPolicy']]
        else
          nil
        end

      if splose_attrs['archived']
        internal_attrs[:archived_at] = splose_attrs['updatedAt']
      else
        internal_attrs[:archived_at] = nil
      end

      internal_attrs[:full_name] = "#{internal_attrs[:first_name]} #{internal_attrs[:last_name]}".strip

      internal_attrs[:address1] = splose_attrs['addressL1'].presence
      internal_attrs[:address2] = splose_attrs['addressL2'].presence
      internal_attrs[:address3] = splose_attrs['addressL3'].presence
      internal_attrs[:city] = splose_attrs['city'].presence
      internal_attrs[:postcode] = splose_attrs['postalCode'].presence
      internal_attrs[:state] = splose_attrs['state'].presence

      country_code = ISO3166::Country.find_country_by_any_name(splose_attrs['country'].presence || 'Australia')&.alpha2
      internal_attrs[:country] = country_code
      internal_attrs[:country_code] = country_code

      if splose_attrs['phoneNumbers'].present?
        splose_attrs['phoneNumbers'].each do |phone_number|
          if phone_number['type'] == 'Mobile'
            internal_attrs[:mobile] = "#{phone_number['phoneNumber']}".strip
            internal_attrs[:mobile_formated] = TelephoneNumber.parse(internal_attrs[:mobile], country_code).e164_number
          end

          if phone_number['type'] == 'Home'
            internal_attrs[:phone] = "#{phone_number['phoneNumber']}".strip
            internal_attrs[:phone_formated] = TelephoneNumber.parse(internal_attrs[:phone], country_code).e164_number
          end
        end
      end

      # DVA details
      internal_attrs[:dva_details] = {
        dva_file_number: splose_attrs['veteransFileNumber'].presence
      }

      # NDIS details
      splose_ndis_info = splose_attrs['ndisInfo'] || {}
      local_ndis_details = {
        ndis_client_number: splose_attrs['ndisNumber'].presence,
        ndis_plan_manager_name: "#{splose_ndis_info['nomineeFirstName']} #{splose_ndis_info['nomineeLastName']}".strip.presence,
        ndis_plan_manager_phone: "#{splose_ndis_info['nomineeMobileCode']}#{splose_ndis_info['nomineeMobileNumber']}".strip.presence,
        ndis_plan_manager_email: splose_ndis_info['nomineeEmail'].presence,
        ndis_fund_management: splose_ndis_info['fundManagement'].presence,
        ndis_diagnosis: splose_ndis_info['diagnosis'].presence
      }

      if splose_ndis_info['startDate']
        local_ndis_details[:ndis_plan_start_date] = Date.parse(splose_ndis_info['startDate']).strftime('%Y-%m-%d') rescue nil
      end
      if splose_ndis_info['endDate']
        local_ndis_details[:ndis_plan_end_date] = Date.parse(splose_ndis_info['endDate']).strftime('%Y-%m-%d') rescue nil
      end

      if local_ndis_details.values.any?(&:present?)
        internal_attrs[:ndis_details] = local_ndis_details
      else
        internal_attrs[:ndis_details] = nil
      end

      # Medicare details
      local_medicare_details = {
        medicare_card_number: splose_attrs['medicareNumber'].presence,
        medicare_card_irn: splose_attrs['irn'].presence
      }

      if local_medicare_details.values.any?(&:present?)
        internal_attrs[:medicare_details] = local_medicare_details
      else
        internal_attrs[:medicare_details] = nil
      end

      # Private health insurance details
      splose_health_fund = splose_attrs['healthFund'] || {}
      local_hi_details = {
        hi_company_name: splose_health_fund['name'].presence,
        hi_number: splose_health_fund['membershipNumber'].presence,
        hi_patient_number: splose_health_fund['patientNumber'].presence,
        hi_manager_email: splose_health_fund['email'].presence,
        hi_manager_phone: splose_health_fund['phone'].presence
      }

      if local_hi_details.values.any?(&:present?)
        internal_attrs[:hi_details] = local_hi_details
      else
        internal_attrs[:hi_details] = nil
      end

      # Tags
      splose_patient_tags = splose_attrs['patientTags'] || []
      local_tag_ids = []

      if splose_patient_tags.present?
        splose_patient_tags.each do |tag_name|
          # Find if tag already exists in the business
          tag_name = tag_name.strip
          if @patient_tags.value?(tag_name)
            local_tag_ids << @patient_tags.key(tag_name)
          else
            # Create new tag if it does not exist
            new_tag = ::Tag.create!(
              business_id: @business.id,
              name: tag_name,
              color: '#000000', # Default to black if no color provided
              tag_type: ::Tag::TYPE_PATIENT
            )
            @patient_tags[new_tag.id] = tag_name
            local_tag_ids << new_tag.id
          end
        end
      end

      if local_tag_ids.any?
        internal_attrs[:tag_ids] = local_tag_ids
      else
        internal_attrs[:tag_ids] = []
      end

      # Other info
      general_info_lines = [splose_attrs['extraInfo'].presence]

      if splose_attrs['emergencyContactName'].present? || splose_attrs['emergencyContactNumber'].present?
        general_info_lines << "Emergency contact: #{splose_attrs['emergencyContactName'].to_s.strip} (#{splose_attrs['emergencyContactNumber'].to_s.strip})"
      end

      internal_attrs[:general_info] = general_info_lines.compact.join("\n\n").strip.presence

      # Timestamps
      internal_attrs[:created_at] = Time.parse(splose_attrs['createdAt']) if splose_attrs['createdAt'].present?
      internal_attrs[:updated_at] = Time.parse(splose_attrs['updatedAt']) if splose_attrs['updatedAt'].present?
      internal_attrs[:deleted_at] = Time.parse(splose_attrs['deletedAt']) if splose_attrs['deletedAt'].present?

      internal_attrs
    end

    def map_associated_contacts(splose_attrs)
      associations = []

      splose_invoice_to_contact_id = splose_attrs['invoiceRecipientId'].presence
      if splose_invoice_to_contact_id.present?
        import_contact = SploseImportRecord.find_by(
          business_id: @business.id,
          reference_id: splose_invoice_to_contact_id,
          resource_type: 'Contact'
        )

        if import_contact.present?
          associations << {
            type: PatientContact::TYPE_INVOICE_TO,
            contact_id: import_contact.internal_id
          }
        end
      end

      if splose_attrs['emergencyContactName'].present? && splose_attrs['emergencyContactNumber'].present?
        # Splose data sample:
        # "emergencyContactNumber": "0123456",
        # "emergencyContactName": "Test emergency contact",
        # "emergencyContactRelationship": "Wife"
        emergency_contact = ::Contact.find_or_create_by!(
          business_id: @business.id,
          business_name: splose_attrs['emergencyContactName'].strip,
          phone: splose_attrs['emergencyContactNumber'].strip
        ) do |contact|
          contact.contact_type = 'Emergency'
        end

        associations << {
          type: PatientContact::TYPE_EMERGENCY,
          contact_id: emergency_contact.id
        }
      end

      associations
    end

    class SploseImportRecord < ActiveRecord::Base
      self.table_name = 'splose_records'
    end

    class ImportPatient < ::ActiveRecord::Base
      self.table_name = 'patients'

      has_and_belongs_to_many :tags, class_name: 'Tag', join_table: 'patients_tags', foreign_key: 'patient_id', association_foreign_key: 'tag_id'
    end

    def log(what)
      puts "[SPLOSE_IMPORT] #{what}"
    end

    business_id = ENV['business_id']
    api_key = ENV['api_key']
    @force_update = ENV['force_update'] == '1' || ENV['force_update'] == 'true'
    @splose_base_url = ENV['splose_base_url'].presence
    # @update_since = ENV['update_since'].presence # TODO: apply this to import only records updated since this date. @see: https://docs.splose.com/api-reference/endpoints/patient/get-a-paged-array-of-patients#parameter-update-gt

    if business_id.blank? || api_key.blank?
      raise ArgumentError, "Business ID or API key is missing!"
    end

    @business = Business.find(business_id)

    log "Business to processed: ##{@business.name} | Users: #{@business.users.count} | Patients: #{@business.patients.count}"

    @sync_start_at = Time.current
    log "Import starting: #{@sync_start_at.iso8601}. Business ##{business_id} - #{@business.name}"

    @api_client = SploseApi::Client.new(api_key)

    @total = 0
    @total_creations = 0
    @total_updates = 0
    @patient_tags = @business.tags.type_patient.pluck(:id, :name).to_h

    def fetch_with_retry(url, max_attempts = 3)
      attempt = 1

      while attempt <= max_attempts
        begin
          log "API call attempt #{attempt}/#{max_attempts} for URL: #{url}"
          return @api_client.call(:get, url)
        rescue SploseApi::Exception => e
          # Check if it's a 429 rate limit error using status_code property
          is_rate_limit_error = e.respond_to?(:status_code) && e.status_code == 429

          if is_rate_limit_error && attempt < max_attempts
            wait_time = 10 * attempt # Linear backoff: 10, 20, 30 seconds
            log "Rate limit hit (429 Too Many Requests). Status code: #{e.status_code}. Waiting #{wait_time} seconds before retry #{attempt + 1}/#{max_attempts}..."
            sleep(wait_time)
            attempt += 1
          else
            if is_rate_limit_error
              log "Max retry attempts (#{max_attempts}) reached for rate limiting. Exiting import."
              raise "Import failed: Maximum retry attempts reached due to rate limiting (status: #{e.status_code})"
            else
              # Re-raise non-rate-limit errors immediately
              log "Error encountered: #{e.message} (status: #{e.respond_to?(:status_code) ? e.status_code : 'unknown'})"
              raise e
            end
          end
        end
      end
    end

    def fetch_patients(url = '/v1/patients?include_archived=true')
      log "Fetching patients ... "
      res = fetch_with_retry(url)
      patients = res['data'] || []
      log "Got: #{patients.count} records."

      patients.each do |patient_raw_attrs|
        ActiveRecord::Base.transaction do
          patient_raw_attrs

          import_record = SploseImportRecord.find_or_initialize_by(
            business_id: @business.id,
            reference_id: patient_raw_attrs['id'],
            resource_type: 'Patient'
          )

          mapped_patient_attrs = map_patient_attrs(patient_raw_attrs)
          mapped_associated_contacts = map_associated_contacts(patient_raw_attrs)

          if @splose_base_url.present?
            import_record.reference_url = "#{@splose_base_url}/patients/#{patient_raw_attrs['id']}"
          end

          if import_record.new_record?
            local_patient = ImportPatient.new mapped_patient_attrs

            local_patient.business_id = @business.id
            local_patient.save!

            mapped_associated_contacts.each do |association_attrs|
              ::PatientContact.create!(
                patient_id: local_patient.id,
                contact_id: association_attrs[:contact_id],
                type: association_attrs[:type]
              )
            end

            import_record.internal_id = local_patient.id
            import_record.last_synced_at = @sync_start_at
            import_record.save!

            log " - Created: ##{local_patient.id} | Ref ID: #{patient_raw_attrs['id']}"
            @total_creations += 1
          else
            # TODO: compare with updated_at on local record is better
            if @force_update || Time.parse(patient_raw_attrs['updatedAt']) > import_record.last_synced_at
              local_patient = ImportPatient.find_by(
                id: import_record.internal_id
              )
              if local_patient.nil? # Already synced before but deleted now
                local_patient = ImportPatient.new
                @total_creations += 1
              else
                @total_updates += 1
              end

              local_patient.assign_attributes mapped_patient_attrs
              local_patient.save!

              mapped_associated_contacts.each do |association_attrs|
                ::PatientContact.find_or_create_by!(
                  patient_id: local_patient.id,
                  contact_id: association_attrs[:contact_id],
                  type: association_attrs[:type],
                )
              end

              import_record.internal_id = local_patient.id
              import_record.last_synced_at = @sync_start_at
              import_record.save!
              log " - Updated: ##{local_patient.id} | Ref ID: #{patient_raw_attrs['id']}"
            else
              # log "Patient ##{patient_raw_attrs['id']} already imported. SKIPPED"
            end
          end
        end
      end

      @total += patients.count

      if res['links']['nextPage'].present?
        log "Next page found. Fetching more patients ..."
        sleep(5)
        fetch_patients(res['links']['nextPage'])
      end
    end

    fetch_patients

    log "Import finished:"
    log "Total:     #{@total}"
    log "Creations: #{@total_creations}"
    log "Updates:   #{@total_updates}"
    log "Time:      #{(Time.current - @sync_start_at).round(1)} secs"
  end
end
